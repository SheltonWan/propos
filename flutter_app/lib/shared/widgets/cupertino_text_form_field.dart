import 'package:flutter/cupertino.dart';

/// iOS 风格文本表单输入框，支持 [Form] 验证框架。
///
/// 将 [CupertinoTextField] 封装为 [FormField<String>]，在字段下方内联展示验证错误文本。
/// 验证器忽略 FormField 内部值，直接读取 [controller.text]，
/// 确保外部回填（记住密码、OTP 等）场景下验证结果始终正确。
class CupertinoTextFormField extends FormField<String> {
  CupertinoTextFormField({
    super.key,
    required TextEditingController controller,
    String? placeholder,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    FormFieldValidator<String>? validator,
    Widget? prefix,
    Widget? suffix,
    int? maxLength,
    void Function(String)? onFieldSubmitted,
    super.autovalidateMode,
  }) : super(
          // 忽略 FormField 传入的 value 参数，直接读取 controller，确保外部回填同步
          validator: validator != null ? (_) => validator(controller.text) : null,
          builder: (FormFieldState<String> field) {
            final hasError = field.hasError && field.errorText != null;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoTextField(
                  controller: controller,
                  placeholder: placeholder,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  textInputAction: textInputAction,
                  maxLength: maxLength,
                  prefix: prefix != null
                      ? Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: prefix,
                        )
                      : null,
                  suffix: suffix != null
                      ? Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: suffix,
                        )
                      : null,
                  decoration: BoxDecoration(
                    color: CupertinoColors.tertiarySystemFill,
                    borderRadius: BorderRadius.circular(10),
                    border: hasError
                        ? Border.all(
                            color: CupertinoColors.destructiveRed,
                            width: 1.0,
                          )
                        : null,
                  ),
                  padding: EdgeInsets.only(
                    left: prefix != null ? 8 : 12,
                    right: suffix != null ? 4 : 12,
                    top: 14,
                    bottom: 14,
                  ),
                  onChanged: (_) => field.didChange(controller.text),
                  onSubmitted: onFieldSubmitted,
                  style: const TextStyle(fontSize: 16),
                ),
                if (hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      field.errorText!,
                      style: const TextStyle(
                        color: CupertinoColors.destructiveRed,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
}
