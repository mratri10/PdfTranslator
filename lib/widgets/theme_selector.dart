import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf_translator/models/reader_theme.dart';
import 'package:pdf_translator/providers/reader_provider.dart';

class ThemeSelector extends StatelessWidget {
  final bool showLabel;

  const ThemeSelector({super.key, this.showLabel = false});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReaderProvider>(context);
    final themes = ReaderTheme.allThemes;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: themes.map((theme) {
        final isSelected = provider.currentTheme.type == theme.type;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: Tooltip(
            message: theme.name,
            child: GestureDetector(
              onTap: () => provider.changeTheme(theme),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: isSelected ? 34.0 : 28.0,
                height: isSelected ? 34.0 : 28.0,
                decoration: BoxDecoration(
                  color: theme.backgroundColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected 
                        ? theme.accentColor 
                        : theme.textColor.withOpacity(0.3),
                    width: isSelected ? 2.5 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: theme.accentColor.withOpacity(0.3),
                            blurRadius: 6,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: Container(
                    width: 14.0,
                    height: 14.0,
                    decoration: BoxDecoration(
                      color: theme.textColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
