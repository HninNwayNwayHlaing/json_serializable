// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'package:test/test.dart';

import 'generic_files/generic_class.dart';
import 'test_files/json_test_example.dart';
import 'test_utils.dart';

void main() {
  group('generic', () {
    GenericClass<T, S> roundTripGenericClass<T extends num, S>(
        GenericClass<T, S> p) {
      var outputJson = loudEncode(p);
      var p2 = new GenericClass<T, S>.fromJson(
          jsonDecode(outputJson) as Map<String, dynamic>);
      var outputJson2 = loudEncode(p2);
      expect(outputJson2, outputJson);
      return p2;
    }

    test('no type args', () {
      roundTripGenericClass(new GenericClass()
        ..fieldDynamic = 1
        ..fieldInt = 2
        ..fieldObject = 3
        ..fieldT = 5
        ..fieldS = 'six');
    });
    test('with type arguments', () {
      roundTripGenericClass(new GenericClass<double, String>()
        ..fieldDynamic = 1
        ..fieldInt = 2
        ..fieldObject = 3
        ..fieldT = 5.0
        ..fieldS = 'six');
    });
    test('with bad arguments', () {
      expect(
          () => new GenericClass<double, String>()
            ..fieldT = (5 as dynamic) as double,
          throwsA(isACastError));
    });
    test('with bad arguments', () {
      expect(
          () => new GenericClass<double, String>()
            ..fieldS = (5 as dynamic) as String,
          throwsA(isACastError));
    });
  });
  group('Person', () {
    roundTripPerson(Person p) {
      roundTripObject(p, (json) => new Person.fromJson(json));
    }

    test('null', () {
      roundTripPerson(new Person(null, null, null));
    });

    test('empty', () {
      roundTripPerson(new Person('', '', null,
          middleName: '',
          dateOfBirth: new DateTime.fromMillisecondsSinceEpoch(0)));
    });

    test('now', () {
      roundTripPerson(new Person('a', 'b', House.gryffindor,
          middleName: 'c', dateOfBirth: new DateTime.now()));
    });

    test('now toUtc', () {
      roundTripPerson(new Person('a', 'b', House.hufflepuff,
          middleName: 'c', dateOfBirth: new DateTime.now().toUtc()));
    });

    test('empty json', () {
      var person = new Person.fromJson({});
      expect(person.dateOfBirth, isNull);
      roundTripPerson(person);
    });
  });

  group('Order', () {
    roundTripOrder(Order p) {
      roundTripObject(p, (json) => new Order.fromJson(json));
    }

    test('null', () {
      roundTripOrder(new Order(Category.charmed));
    });

    test('empty', () {
      roundTripOrder(new Order(Category.strange, const [])
        ..count = 0
        ..isRushed = false);
    });

    test('simple', () {
      roundTripOrder(new Order(Category.top, <Item>[
        new Item(24)
          ..itemNumber = 42
          ..saleDates = [new DateTime.now()]
      ])
        ..count = 42
        ..isRushed = true);
    });

    test('almost empty json', () {
      var order = new Order.fromJson({'category': 'top'});
      expect(order.items, isEmpty);
      expect(order.category, Category.top);
      roundTripOrder(order);
    });

    test('required, but missing enum value fails', () {
      expect(() => new Order.fromJson({}), throwsStateError);
    });

    test('mismatched enum value fails', () {
      expect(() => new Order.fromJson({'category': 'weird'}), throwsStateError);
    });

    test('platform', () {
      var order = new Order(Category.charmed)
        ..platform = Platform.undefined
        ..altPlatforms = {
          'u': Platform.undefined,
          'f': Platform.foo,
          'null': null
        };

      roundTripOrder(order);
    });
  });

  group('Item', () {
    roundTripItem(Item p) {
      roundTripObject(p, (json) => new Item.fromJson(json));
    }

    test('empty json', () {
      var item = new Item.fromJson({});
      expect(item.saleDates, isNull);
      roundTripItem(item);

      expect(item.toJson().keys, orderedEquals(['price', 'saleDates', 'rates']),
          reason: 'Omits null `itemNumber`');
    });

    test('set itemNumber - with custom JSON key', () {
      var item = new Item.fromJson({'item-number': 42});
      expect(item.itemNumber, 42);
      roundTripItem(item);

      expect(item.toJson().keys,
          orderedEquals(['price', 'item-number', 'saleDates', 'rates']),
          reason: 'Includes non-null `itemNumber` - with custom key');
    });
  });

  group('Numbers', () {
    roundTripNumber(Numbers p) {
      roundTripObject(p, (json) => new Numbers.fromJson(json));
    }

    test('simple', () {
      roundTripNumber(new Numbers()
        ..nums = [0, 0.0]
        ..doubles = [0.0]
        ..nnDoubles = [0.0]
        ..ints = [0]
        ..duration = const Duration(seconds: 1)
        ..date = new DateTime.now());
    });

    test('custom DateTime', () {
      var instance = new Numbers()
        ..date = new DateTime.fromMicrosecondsSinceEpoch(42);
      var json = instance.toJson();
      expect(json, containsPair('date', 42));
    });

    test('support ints as doubles', () {
      var value = {
        'doubles': [0, 0.0, null],
        'nnDoubles': [0, 0.0]
      };

      roundTripNumber(new Numbers.fromJson(value));
    });

    test('does not support doubles as ints', () {
      var value = {
        'ints': [0.0, 0],
      };

      expect(() => new Numbers.fromJson(value),
          throwsA(const isInstanceOf<CastError>()));
    });
  });
}
