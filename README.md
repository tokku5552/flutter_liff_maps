# flutter_liff_maps

## Feature

- 自分の近くにある公園を探すことができる。
- チェックインすることができる。
- 公園ごとにチェックインした人が見える。
- 友人がチェックインしたら通知が来る。

## UI

- 公園マップ画面

## modeling

- 公園
  - geo
    - hash
    - geopoint
      - latitude
      - longitude
  - 名前
  - チェックイン[]
- ユーザー
  - 名前
  - チェックイン[]
- チェックイン
  - 公園 id
  - ユーザー id
  - 日時

## firestore

- parks
  - geo
    - hash
    - geopoint
      - latitude
      - longitude
  - name
- chekins
  - userId
  - parkId
  - date
- users
  - lineId
  - name
