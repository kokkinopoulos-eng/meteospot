with open("C:/meteospot/lib/screens/settings_screen.dart", "r", encoding="utf-8") as f:
    content = f.read()

# Check if url_launcher is imported
if "url_launcher" not in content:
    content = content.replace(
        "import 'package:flutter_secure_storage/flutter_secure_storage.dart';\n",
        "import 'package:flutter_secure_storage/flutter_secure_storage.dart';\nimport 'package:url_launcher/url_launcher.dart';\n",
        1
    )

# Add a help button after the TextField in the google card
old = '''                onPressed: () => setState(() => _showGooglePlacesKey = !_showGooglePlacesKey),
              ),
            ),
          ),
        ],
      ),
    );
  }
'''

new = '''                onPressed: () => setState(() => _showGooglePlacesKey = !_showGooglePlacesKey),
              ),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final uri = Uri.parse('https://developers.google.com/maps/documentation/places/web-service/get-api-key');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: const Row(children: [
              Icon(Icons.open_in_new, color: Colors.teal, size: 16),
              SizedBox(width: 6),
              Text('\\u03a0\\u03ce\\u03c2 \\u03bd\\u03b1 \\u03c0\\u03ac\\u03c1\\u03c9 \\u03b4\\u03c9\\u03c1\\u03b5\\u03ac\\u03bd Google Places key',
                  style: TextStyle(color: Colors.teal, fontSize: 13, decoration: TextDecoration.underline)),
            ]),
          ),
        ],
      ),
    );
  }
'''

content = content.replace(old, new, 1)

with open("C:/meteospot/lib/screens/settings_screen.dart", "w", encoding="utf-8") as f:
    f.write(content)

print("Done")
