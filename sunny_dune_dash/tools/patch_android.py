import re
p = 'android/app/src/main/AndroidManifest.xml'
s = open(p, encoding='utf-8').read()
meta = '''<meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="ca-app-pub-8825505611074662~7640228894"/>
    </application>'''
if 'APPLICATION_ID' not in s:
    s = s.replace('</application>', meta, 1)
s = re.sub(r'android:label="[^"]*"', 'android:label="Sunny Dune Dash"', s, count=1)
open(p, 'w', encoding='utf-8').write(s)
print('Manifest patché')
