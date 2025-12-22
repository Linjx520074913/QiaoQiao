"""
快速账单解析器 - 性能优化版本
"""

import json
import logging
from typing import Optional

from ..models import Invoice, InvoiceParseResult
from ..llm import OllamaEngine

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class FastBillParser:
    """快速账单解析器 - 牺牲少量准确率换取速度"""

    # 精简的提示词（无 few-shot 示例）- 优化版
    FAST_PROMPT_TEMPLATE = """你是账单信息提取助手。从文本中提取账单信息并输出 JSON。

提取字段：
- invoice_type, invoice_number, invoice_date, seller_name, buyer_name, buyer_phone, buyer_address, total_amount, items

核心规则：
1. 金额和数量必须是纯数字（如 16.2, 1），不要货币符号和单位
2. 无法确定的字段设为 null
3. 必须输出有效的 JSON，不要其他文字

seller_name 提取规则（按优先级）：
1. 【最高优先】查找"下单时间"或"订单时间"后面的商家名
2. 【次优先】文本开头的品牌名
3. 【品牌提取】只保留品牌主体，去除门店后缀
   - "杨氏手撕烤鸭（丁头村店）" → "杨氏手撕烤鸭"
   - "星巴克(天环店)" → "星巴克"
4. 【必须排除】不要提取：
   - 保险名称（准时保、食安险）
   - 平台名称（美团、饿了么）
   - 配送服务（骑手配送、外送服务）
   - 仅门店名（"丁头村店"、"万象城店"）

total_amount 提取规则（按优先级）：
1. 【最高优先】"实付"、"实付款"后的金额
2. 【次优先】"应付"、"应付金额"后的金额
3. 【第三优先】"合计"后的金额（排除"优惠合计"）
4. 【第四优先】"总计"后的金额
5. 【最后】商品总价（所有 items 的 amount 之和）
6. 【必须排除】负数、优惠金额、"到手"金额

items 提取规则：
1. 【商品识别】只提取实际商品名称和价格
2. 【商品说明】以下是说明不是独立商品，应忽略：
   - 包含"份量"、"口味"、"备注"、"规格"、"加料"、"温度"
   - 包含"选择"、"备注说明"、"口味偏好"
3. 【商品分组】看到"数量×N"或"商品总价"时，前面信息为一组
4. 【金额选择】商品 amount 是原价（商品总价），不是"到手价"
5. 【去重】一个商品只能有一个 amount，不要重复

invoice_type 提取规则：
- 提取订单类型（如：外卖订单、咖啡订单、发票、收据、银行流水）
- 不要提取金额标签（如"实付"、"合计"）

示例1（外卖订单 - 商品说明识别）：
输入：
"手撕烤鸭半只
到手￥7.87
份量，孜然辣椒
￥26.9
数量×1
商品总价 ￥26.9"

输出：
{{
  "items": [{{"name": "手撕烤鸭半只", "quantity": 1, "amount": 26.9}}],
  "total_amount": 26.9
}}
说明：份量是说明不是商品，到手价不是商品价格

示例2（咖啡订单 - 商家名提取）：
输入：
"南山智谷店（No.10649）
下单时间：2025-12-08 19:14 luckincoffee小程序
生椰拿铁 ￥9.9
实付款：¥9.9"

输出：
{{
  "seller_name": "luckincoffee",
  "items": [{{"name": "生椰拿铁", "quantity": 1, "amount": 9.9}}],
  "total_amount": 9.9
}}
说明：商家名从"下单时间"后提取，去除"小程序"后缀

示例3（多商品订单 - 优惠处理）：
输入：
"商品1 ￥15.0
商品2 ￥20.0
商品总价 ￥35.0
优惠合计 -5.0
实付 ￥30.0"

输出：
{{
  "items": [
    {{"name": "商品1", "quantity": 1, "amount": 15.0}},
    {{"name": "商品2", "quantity": 1, "amount": 20.0}}
  ],
  "total_amount": 30.0
}}
说明：商品价格取原价，总金额取实付（不是商品总价）

输入文本：
{text}

输出 JSON（只输出JSON，不要其他文字）："""

    # 极简提示词（仅提取商家名和金额）- 优化版
    SUMMARY_PROMPT_TEMPLATE = """从文本提取商家名和金额，输出 JSON。

字段：
- seller_name: 商家品牌名称
- total_amount: 总金额（纯数字）

seller_name 提取规则（按优先级）：
1. 【最高优先】查找"下单时间"或"订单时间"后面紧跟的商家名
2. 【次优先】在"商品费用"、"合计"、"进商家"前查找完整商家名
3. 【第三优先】文本开头的品牌名（如果没有找到第1、2条）
4. 【必须排除】以下内容不是商家名：
   - 配送服务（包含"配送"、"骑手"、"外送"）
   - 保险服务（包含"保"、"险"）
   - 平台名称（"美团外卖"、"饿了么"单独出现时）
5. 【重要】必须保留完整商家名（包括特色菜品和门店）
   - ✓ "德园闰肠粉·蚝油捞·炖汤（西丽店）"（完整）
   - ✗ "德园"（不完整，缺少特色和门店）
   - 说明：餐饮商家名通常包含特色菜品（如"闰肠粉·蚝油捞"）

total_amount 提取规则（按优先级）：
1. 【最高优先】"实付"、"实付款"后的金额（寻找￥符号后的数字）
2. 【次优先】"应付"、"应付金额"后的金额
3. 【第三优先】"合计"后的金额（必须排除"优惠合计"、"优惠券合计"）
4. 【必须排除】负数金额、优惠金额、"到手"金额、券后价、原价
5. 【提取方法】在"实付款"这一行查找￥后的完整数字（包括小数点）
6. 金额范围：必须在 0.01-50000 之间

示例1（外卖订单）：
输入文本：
"南山智谷店（No.10649）
骑手配送
下单时间：2025-12-08 19:14 luckincoffee小程序
优惠合计：-2.0
实付款：¥9.9"

输出：{{"seller_name": "luckincoffee", "total_amount": 9.9}}

示例4（淘宝订单）：
输入文本：
"麦当劳虾块麦乐鸡20块买一送￥18.69
到店自助链接；麦乐鸡20块（早1...
不支持7天无理由
价格明细
实付款￥18.69"

输出：{{"seller_name": "麦当劳", "total_amount": 18.69}}

示例2（餐饮订单）：
输入文本：
"杨氏手撕烤鸭（丁头村店）
准时保 ¥0.5
应付：¥34.6
优惠：-2.0"

输出：{{"seller_name": "杨氏手撕烤鸭", "total_amount": 34.6}}

示例3（咖啡订单）：
输入文本：
"星巴克（天环店A03）
下单时间 2025-12-08 Starbucks官方
到手价 ¥25.8
实付 ¥28.0"

输出：{{"seller_name": "Starbucks", "total_amount": 28.0}}

示例5（美团外卖 - 必须提取完整商家名）：
输入文本：
"感谢您对美团外卖的信任
商品费用
德园闰肠粉·蚝油捞·炖汤（西丽店）
进商家粉丝群
共1件
合计￥15.3"

正确输出：{{"seller_name": "德园闰肠粉·蚝油捞·炖汤（西丽店）", "total_amount": 15.3}}
错误示例：{{"seller_name": "德园", ...}}  # ❌ 只提取品牌前缀，丢失了特色菜品和门店信息

文本：
{text}

输出 JSON（只输出JSON，不要其他文字）："""

    def __init__(
        self,
        llm_engine: OllamaEngine,
        validate_output: bool = False,  # 快速模式默认不验证
        skip_items: bool = False,  # 是否跳过商品明细
    ):
        """
        初始化快速解析器

        Args:
            llm_engine: LLM 推理引擎
            validate_output: 是否验证输出（关闭以提升速度）
            skip_items: 是否跳过商品明细（仅提取总金额等关键信息）
        """
        self.llm_engine = llm_engine
        self.validate_output = validate_output
        self.skip_items = skip_items
        mode = "summary mode" if skip_items else "optimized for speed"
        logger.info(f"FastBillParser initialized ({mode})")

    def parse(self, ocr_text: str) -> InvoiceParseResult:
        """
        快速解析账单

        Args:
            ocr_text: OCR 识别的文本

        Returns:
            账单解析结果
        """
        try:
            # 根据模式选择提示词和 max_tokens
            if self.skip_items:
                # 使用完整文本以确保能找到商家名（可能在末尾）
                prompt = self.SUMMARY_PROMPT_TEMPLATE.format(text=ocr_text)
                # 优化：增加 max_tokens 确保 LLM 有足够空间理解提示词并输出完整 JSON
                # 提示词约 800 tokens + 输出 JSON 约 50 tokens = 至少需要 200 tokens
                max_tokens = 200  # 从 100 增加到 200，提升理解准确性
                logger.info(f"Summary parsing (text length: {len(ocr_text)}, max_tokens: {max_tokens})")
            else:
                prompt = self.FAST_PROMPT_TEMPLATE.format(text=ocr_text)
                # 完整模式需要更多输出空间（包含 items 数组）
                max_tokens = 512  # 标准输出
                logger.info(f"Fast parsing (text length: {len(ocr_text)}, max_tokens: {max_tokens})")

            # 调用 LLM - 使用更低温度和优化的 token 限制
            json_output = self.llm_engine.generate_json(
                prompt=prompt,
                temperature=0.0,  # 最低温度，更快
                max_tokens=max_tokens,
            )

            # 添加原始文本（在清理之前，以便清理函数可以访问）
            json_output["raw_text"] = ocr_text

            # 清理数据（移除货币符号和单位）
            json_output = self._clean_output(json_output)

            # 转换为 Invoice 对象
            invoice = Invoice(**json_output)

            return InvoiceParseResult(
                success=True,
                invoice=invoice,
                confidence=0.8,  # 快速模式固定置信度
            )

        except Exception as e:
            logger.error(f"Fast parsing error: {e}")
            return InvoiceParseResult(
                success=False,
                error_message=str(e),
            )

    def _clean_output(self, data: dict) -> dict:
        """
        清理 LLM 输出，移除货币符号和单位

        Args:
            data: LLM 输出的字典

        Returns:
            清理后的字典
        """
        import re
        from datetime import datetime

        def clean_number(value):
            """清理数字字符串"""
            if value is None:
                return None
            if isinstance(value, (int, float)):
                return value
            if isinstance(value, str):
                # 移除货币符号: ￥ ¥ $ €
                value = re.sub(r'[￥¥$€]', '', value)
                # 移除单位: × x 份 件 个
                value = re.sub(r'[×x份件个]', '', value)
                # 移除空格
                value = value.strip()
                # 尝试转换为数字
                try:
                    return float(value) if '.' in value else int(value)
                except:
                    return None
            return None

        # 清理顶层金额字段
        for field in ['total_amount', 'subtotal', 'tax_amount']:
            if field in data and data[field]:
                data[field] = clean_number(data[field])

        # 清理商品列表
        if 'items' in data and isinstance(data['items'], list):
            for item in data['items']:
                if isinstance(item, dict):
                    for field in ['quantity', 'unit_price', 'amount']:
                        if field in item and item[field]:
                            item[field] = clean_number(item[field])

            # 去重：只删除明确是规格说明的项（包含特定关键词）
            if len(data['items']) > 1:
                deduplicated = []
                for item in data['items']:
                    name = item.get('name', '')
                    # 如果商品名包含"份量"、"口味"等关键词，这是说明不是商品
                    if any(keyword in name for keyword in ['份量', '口味', '备注', '规格', '加料', '温度']):
                        continue
                    deduplicated.append(item)

                # 如果去重后还有商品，使用去重后的列表
                if deduplicated:
                    data['items'] = deduplicated

        # 修复总金额：优先从原始文本提取"合计/实付/应付"（更可靠）
        if 'total_amount' in data:
            raw_text = data.get('raw_text', '')

            # 始终尝试从原始文本提取总金额（比 LLM 计算更准确）
            extracted_amount = None

            # 按优先级尝试提取: 实付 > 应付 > 合计
            # (实付最准确，合计可能被误匹配为"优惠合计")
            if extracted_amount is None:
                patterns = [
                    r'实付[：:\s]*[￥¥]?([\d.]+)',  # 实付: ¥9.9
                    r'应付[：:\s]*[￥¥]?([\d.]+)',  # 应付: ¥34.6
                ]
                for pattern in patterns:
                    matches = re.findall(pattern, raw_text)
                    if matches:
                        extracted_amount = float(matches[-1])
                        break

            # 如果还没找到，尝试"合计"（需要特殊处理，避免误匹配"优惠合计"）
            if extracted_amount is None:
                # 只匹配不是以"优惠"开头的"合计"
                match = re.search(r'(?<!优惠)(?<!优惠券)(?<!优惠减免)合计[^\n]*\n[^\n]*', raw_text)
                if match:
                    section = match.group()
                    numbers = re.findall(r'[¥￥]([\d.]+)', section)
                    if numbers:
                        extracted_amount = float(numbers[-1])

            # 如果从文本提取成功，优先使用提取的金额
            if extracted_amount is not None and extracted_amount > 0:
                data['total_amount'] = extracted_amount
            # 否则，如果 LLM 返回的金额有问题（负数或 None），使用商品总价
            elif data['total_amount'] is None or (isinstance(data['total_amount'], (int, float)) and data['total_amount'] <= 0):
                if 'items' in data and data['items']:
                    total = sum(item.get('amount', 0) or 0 for item in data['items'])
                    if total > 0:
                        data['total_amount'] = total

        # 如果没有提取到日期，使用当前系统时间
        if 'invoice_date' not in data or not data['invoice_date']:
            data['invoice_date'] = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

        return data

    def parse_batch(self, ocr_texts: list[str]) -> list[InvoiceParseResult]:
        """批量快速解析"""
        results = []
        for i, text in enumerate(ocr_texts):
            logger.info(f"Fast parsing {i + 1}/{len(ocr_texts)}")
            result = self.parse(text)
            results.append(result)
        return results

    def to_json(self, result: InvoiceParseResult, indent: int = 2) -> str:
        """转换为 JSON 字符串"""
        return json.dumps(result.to_dict(), ensure_ascii=False, indent=indent)
