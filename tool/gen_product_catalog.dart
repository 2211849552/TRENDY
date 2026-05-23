// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  final keys = File('keys.txt')
      .readAsLinesSync()
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  // معرّفات Unsplash مُختبرة (أزياء ومنتجات)
  const photoIds = [
    '1595777457583-95e059d581b8', '1566174053879-31528523f8ae', '1496747611176-843222e1e57c',
    '1515372039744-b8f02a3ae446', '1572804013309-59a88b7e92f1', '1539003348350-53162a6fa659',
    '1469334031218-e382a71b716b', '1594633312681-425c7b3842e1', '1515886656003-87f172cfcee4',
    '1558618666-fcd25c85cd64', '1583496669800-34167a36deef', '1558176213-26c8e9f8f4b0',
    '1521572163474-6864f9cf17ab', '1622445275463-afa12ab34d44', '1583743814966-8936f5b7be1a',
    '1596755094514-f87e34085b2c', '1602810318383-e386cc2a3f9d', '1618354691373-d851c5c3a990',
    '1523380154753-176aef1f6e19', '1503342217505-b524a27ec63a', '1434389677669-e08b4cac3105',
    '1562157873-818bc0dba4f0', '1617135562427-446a41c84c76', '1556906781-9a4121766cd7',
    '1542291026-7eec264c27ff', '1460353581641-37baddab0ca2', '1549298916-b41d501d3772',
    '1606107557195-0a27c4b4e342', '1595950652106-40cbeaaeb8f3', '1560769629-975ec094d884',
    '1614252238956-18f90da3f85e', '1603487745945-81f139a6e6c3', '1551106844-6812e9374a10',
    '1460353577559-ba3e2260b047', '1543163521-1bf539c55dd2', '1539184771528-4c7a0e655c1e',
    '1590874103328-dc236621dea8', '1584917865442-de89d76ffd68', '1611591437281-460bfac7a2c9',
    '1627123424574-724758594e93', '1523275335684-37898b6baf30', '1553062407-98eeb64c6a62',
    '1548036328-05fbf90b985b', '1590875204030-2a226f9c79e2', '1622563595784-545e976f9b78',
    '1564422179339-aa2e800a19b0', '1591561954557-26939969b180', '1524592261725-4d9f49d6993f',
    '1617035562427-446a41c84c76', '1507679799987-c73779587ccf', '1473966960822-9c5204ec5325',
    '1593032465175-481ac7f401a0', '1490114538077-0a7f8cb49891', '1556905055-8d0e9e80e398',
    '1445205170230-053b83016050', '1509631179647-015733ac6aef', '1520975916090-3105956dac38',
    '1441984904996-e0b49587b851', '1485237142534-962b1d909195', '1519457431-448ea9306f85',
    '1555529669-2269763671c0', '1503454537195-1dcabb73ffb9', '1515484954569-74aefb38b32a',
    '1586105251260-029a74e74062', '1519238263530-4472d6d2da85', '1503919502598-bfbd6ee7873f',
    '1490481651871-ab68de25d43d', '1483985988355-763728e1935b', '1441986300917-64644bd600d8',
    '1541099644240-14f090b49d4a', '1542272604-787c683553e7', '1529139576369-0ba640a38000',
    '1485968643330-54e995616c63', '1475180096624-eb855dffcd15', '1434389677669-e08b4cac3105',
    '1617135562427-446a41c84c76', '1601922632972-0718d5b3e1ee', '1595777457583-95e059d581b8',
  ];

  final unique = <String>[];
  for (final id in photoIds) {
    if (!unique.contains(id)) unique.add(id);
  }

  final buffer = StringBuffer('''
/// صورة فريدة لكل منتج في التطبيق.
const Map<String, String> kProductImageCatalog = {
''');

  for (var i = 0; i < keys.length; i++) {
    final key = keys[i];
    final id = unique[(i * 13 + key.hashCode.abs()) % unique.length];
    final url = 'https://images.unsplash.com/photo-$id?auto=format&fit=crop&w=600&h=700&q=80';
    buffer.writeln("  '$key': '$url',");
  }
  buffer.writeln('};');

  // تعيينات خاصة لمنتجات رجالية رسمية (مثل الصورة المرجعية)
  const special = {
    'prod_oxford_shirt': 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?auto=format&fit=crop&w=600&q=80',
    'prod_wool_suit': 'https://images.unsplash.com/photo-1507679799987-c73779587ccf?auto=format&fit=crop&w=600&q=80',
    'prod_slim_chinos': 'https://images.unsplash.com/photo-1473966960822-9c5204ec5325?auto=format&fit=crop&w=600&q=80',
    'prod_formal_pants': 'https://images.unsplash.com/photo-1473966960822-9c5204ec5325?auto=format&fit=crop&w=600&q=80',
  };

  var content = buffer.toString();
  for (final e in special.entries) {
    content = content.replaceFirst(
      RegExp("'${e.key}': '[^']*',"),
      "'${e.key}': '${e.value}',",
    );
  }

  File('lib/data/product_image_catalog.dart').writeAsStringSync(content);
  print('Generated ${keys.length} entries (${unique.length} base photos)');
}
