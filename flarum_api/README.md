# Flarum REST API 文档

Flarum 提供了 REST API，它不仅被单页应用使用，也可供外部程序调用。API 采用 JSON:API 规范定义的最佳实践。

## 测试环境

本文档基于实际测试环境编写，测试端点：`https://flarum.imikufans.cn/`

## 身份验证

### 认证方式

Flarum API 支持多种认证方式：

1. **会话 Cookies** - 单页应用使用
2. **API 密钥** - 脚本、工具与集成应用的首选方案
3. **访问令牌** - 基于用户的短效令牌

### API 密钥

#### 创建

目前没有用于管理 API 密钥的操作界面，只能在数据库 `api_keys` 表中手动创建。

**创建参数：**

| 参数 | 描述 |
|------|------|
| `key` | 秘钥。需自行生成一个独一无二的长字符串（推荐长度 40 的字母数字组合） |
| `user_id` | 用户 ID，可选项。如果设置了此值，秘钥会被充当为指定的用户 |

**自动填充属性：**

| 属性 | 描述 |
|------|------|
| `id` | 主键。由 MySQL 自动递增填写 |
| `allowed_ips` | IP 白名单。保留字段，尚未使用 |
| `scopes` | 范围。保留字段，尚未使用 |
| `created_at` | 创建时间 |
| `last_activity_at` | 上次使用时间。秘钥被使用时自动更新 |

#### 使用

发起 API 请求时，将秘钥添加到 `Authorization` 请求头即可：

```
Authorization: Token 你的_API_秘钥_值; userId=1
```

- 如果在数据库中为密钥设置了 `user_id` 值，请求头中的 `userId=` 将被忽略
- 否则，任何有效的用户 ID 都可起作用

### 访问令牌

访问令牌（Access Tokens）是基于用户的短效令牌，用于 Cookie 会话。

#### 创建

所有用户均可创建访问令牌。要创建令牌，请使用 `/api/token` 端点并提供用户凭证：

```
POST /api/token HTTP/1.1
Content-Type: application/json

{
    "identification": "用户名",
    "password": "密码"
}
```

**响应示例：**

```json
{
    "token": "****************",
    "userId": "***"
}
```

**实际测试命令：**

```bash
curl -X POST -H "Content-Type: application/json" -d '{"identification":"***","password":"******"}' https://flarum.imikufans.cn/api/token
```

#### 令牌类型

| 类型 | 描述 | 过期时间 | 创建方式 |
|------|------|----------|----------|
| `session` | 默认令牌类型 | 1 小时无活动后 | API 创建 |
| `session_remember` | 长期令牌 | 5 年无活动后 | API 创建（添加 `remember=1`） |
| `developer` | 永久令牌 | 永不过期 | 数据库手动创建 |

#### 使用

发起 API 请求时，将令牌添加到 `Authorization` 请求头即可：

```
Authorization: Token qgxs4MqFq46rPt0BUtxdI2OgiobNB1Sgjd23cpkh
```

- 用户的上次在线时间会随访问令牌的使用而更新
- 所有令牌将在用户注销时一并失效

### CSRF 保护

多数 POST/PUT/DELETE API 端点都有跨站请求伪造（CSRF）保护功能。

- GET 端点无需身份验证即可使用，但只会返回游客可见的内容
- 其他端点均需身份验证方可使用
- 使用 API 密钥或访问令牌时，可跳过 CSRF 保护

## 常用 API 端点

### 1. 获取访问令牌

**端点：** `POST /api/token`

**请求参数：**

| 参数 | 类型 | 描述 |
|------|------|------|
| `identification` | string | 用户名或邮箱 |
| `password` | string | 用户密码 |
| `remember` | boolean | 可选，是否获取长期令牌（session_remember 类型） |

**响应：**

```json
{
    "token": "访问令牌",
    "userId": "用户 ID"
}
```

### 2. 列出全部主题帖

**端点：** `GET /api/discussions`

**请求参数：**

| 参数 | 类型 | 描述 |
|------|------|------|
| `page[offset]` | integer | 分页偏移量（可选） |
| `page[limit]` | integer | 每页数量（可选） |

**响应示例：**

```json
{
  "links": {
    "first": "https://flarum.imikufans.cn/api/discussions",
    "next": "https://flarum.imikufans.cn/api/discussions?page%5Boffset%5D=20"
  },
  "data": [
    {
      "type": "discussions",
      "id": "1",
      "attributes": {
        "title": "iMikufans 社区管理规则",
        "slug": "1-imikufans-she-qu-guan-li-gui-ze",
        "commentCount": 1,
        "participantCount": 1,
        "createdAt": "2025-06-29T15:12:03+08:00",
        "lastPostedAt": "2025-06-29T15:12:03+08:00",
        "lastPostNumber": 1,
        "canReply": true,
        "canRename": false,
        "canDelete": false,
        "canHide": false,
        "isHidden": false,
        "canTag": false,
        "isLocked": false,
        "canLock": false,
        "isSticky": true,
        "canSticky": false,
        "canMerge": false,
        "subscription": null
      },
      "relationships": {
        "user": {
          "data": {
            "type": "users",
            "id": "1"
          }
        },
        "lastPostedUser": {
          "data": {
            "type": "users",
            "id": "1"
          }
        },
        "tags": {
          "data": []
        },
        "firstPost": {
          "data": {
            "type": "posts",
            "id": "1"
          }
        }
      }
    }
  ],
  "included": [
    // 包含相关资源（用户、帖子等）
  ]
}
```

**实际测试命令：**

```bash
curl -X GET -H "Authorization: Token ****************" https://flarum.imikufans.cn/api/discussions
```

### 3. 获取单个主题帖

**端点：** `GET /api/discussions/{id}`

**响应：** 返回指定 ID 的主题帖详细信息，包含所有相关帖子、用户等信息。

**实际测试命令：**

```bash
curl -X GET -H "Authorization: Token ****************" https://flarum.imikufans.cn/api/discussions/1
```

### 4. 获取用户信息

**端点：** `GET /api/users/{id}`

**响应示例：**

```json
{
  "data": {
    "type": "users",
    "id": "124",
    "attributes": {
      "username": "***",
      "displayName": "***",
      "avatarUrl": null,
      "slug": "124",
      "joinTime": "2026-01-04T00:50:35+08:00",
      "discussionCount": 1,
      "commentCount": 1,
      "canEdit": false,
      "canEditCredentials": false,
      "canEditGroups": false,
      "canDelete": false,
      "lastSeenAt": "2026-01-04T01:08:21+08:00",
      "isEmailConfirmed": true,
      "email": "******@outlook.com",
      "markedAllAsReadAt": null,
      "unreadNotificationCount": 0,
      "newNotificationCount": 0,
      "preferences": {
        "followAfterReply": false,
        "flarum-subscriptions.notify_for_all_posts": false,
        "useRichTextEditor": true,
        "richTextCompactParagraphs": false,
        "notify_discussionRenamed_alert": true,
        "notify_userSuspended_alert": true,
        "notify_userSuspended_email": true,
        "notify_userUnsuspended_alert": true,
        "notify_userUnsuspended_email": true,
        "notify_newPost_alert": true,
        "notify_newPost_email": true,
        "notify_postMentioned_alert": true,
        "notify_postMentioned_email": false,
        "notify_userMentioned_alert": true,
        "notify_userMentioned_email": false,
        "notify_groupMentioned_alert": true,
        "notify_groupMentioned_email": false,
        "notify_discussionLocked_alert": true,
        "notify_postLiked_alert": true,
        "discloseOnline": true,
        "indexProfile": true,
        "locale": null
      },
      "isAdmin": false,
      "fof-upload-uploadCountCurrent": 0,
      "fof-upload-uploadCountAll": 0,
      "suspendMessage": null,
      "suspendedUntil": null,
      "canSuspend": false,
      "canEditNickname": true,
      "newFlagCount": 0,
      "fof-upload-uploadSharedFiles": true,
      "fof-upload-accessSharedFiles": true,
      "canMentionGroups": false
    },
    "relationships": {
      "groups": {
        "data": []
      }
    }
  }
}
```

**实际测试命令：**

```bash
curl -X GET -H "Authorization: Token ****************" https://flarum.imikufans.cn/api/users/124
```

### 5. 获取单个帖子

**端点：** `GET /api/posts/{id}`

**响应：** 返回指定 ID 的帖子详细信息，包含帖子内容、作者、所属主题等信息。

**实际测试命令：**

```bash
curl -X GET -H "Authorization: Token ****************" https://flarum.imikufans.cn/api/posts/1
```

### 6. 获取当前用户信息

**端点：** `GET /api/users/me`

**响应：** 返回当前认证用户的详细信息。

### 7. 获取通知列表

**端点：** `GET /api/notifications`

**请求参数：**

| 参数 | 类型 | 描述 |
|------|------|------|
| `filter[unread]` | boolean | 可选，是否只返回未读通知 |
| `page[offset]` | integer | 分页偏移量（可选） |
| `page[limit]` | integer | 每页数量（可选） |

## API 响应结构

Flarum API 遵循 JSON:API 规范，响应结构通常包含以下部分：

1. **links** - 分页链接信息
2. **data** - 主要资源数据
3. **included** - 关联资源数据
4. **meta** - 元数据

### 资源类型

常见的资源类型包括：

- `users` - 用户
- `discussions` - 主题帖
- `posts` - 帖子
- `tags` - 标签
- `notifications` - 通知

## 实际测试结果

使用提供的测试账号进行了以下测试：

- ✅ 成功获取访问令牌
- ✅ 成功获取主题帖列表
- ✅ 成功获取单个主题帖详情
- ✅ 成功获取用户信息
- ✅ 成功获取单个帖子详情

所有 API 端点均正常工作，返回数据符合预期。

## 真实请求返回示例

以下是使用实际测试数据的 API 返回示例，已保护敏感信息：

### 1. 主题帖列表返回示例

```json
{
  "links": {
    "first": "https://flarum.imikufans.cn/api/discussions",
    "next": "https://flarum.imikufans.cn/api/discussions?page%5Boffset%5D=20"
  },
  "data": [
    {
      "type": "discussions",
      "id": "1",
      "attributes": {
        "title": "iMikufans 社区管理规则",
        "slug": "1-imikufans-she-qu-guan-li-gui-ze",
        "commentCount": 1,
        "participantCount": 1,
        "createdAt": "2025-06-29T15:12:03+08:00",
        "lastPostedAt": "2025-06-29T15:12:03+08:00",
        "lastPostNumber": 1,
        "canReply": true,
        "isHidden": false,
        "isLocked": false,
        "isSticky": true
      },
      "relationships": {
        "user": {
          "data": {
            "type": "users",
            "id": "1"
          }
        }
      }
    },
    {
      "type": "discussions",
      "id": "108",
      "attributes": {
        "title": "test",
        "slug": "108-test",
        "commentCount": 1,
        "participantCount": 1,
        "createdAt": "2026-01-03T16:53:16+00:00",
        "lastPostedAt": "2026-01-03T16:53:16+00:00",
        "lastPostNumber": 1,
        "canReply": true,
        "isHidden": false,
        "isLocked": false,
        "isSticky": false
      },
      "relationships": {
        "user": {
          "data": {
            "type": "users",
            "id": "124"
          }
        }
      }
    }
  ]
}
```

### 2. 用户信息返回示例

```json
{
  "data": {
    "type": "users",
    "id": "124",
    "attributes": {
      "username": "SakuraCake",
      "displayName": "SakuraCake",
      "avatarUrl": null,
      "joinTime": "2026-01-04T00:50:35+08:00",
      "discussionCount": 1,
      "commentCount": 1,
      "lastSeenAt": "2026-01-04T01:08:21+08:00",
      "isEmailConfirmed": true,
      "email": "***@outlook.com",
      "isAdmin": false,
      "preferences": {
        "followAfterReply": false,
        "useRichTextEditor": true,
        "discloseOnline": true,
        "indexProfile": true
      }
    }
  }
}
```

### 3. 单个帖子返回示例

```json
{
  "data": {
    "type": "posts",
    "id": "108",
    "attributes": {
      "number": 1,
      "createdAt": "2026-01-03T16:53:16+00:00",
      "contentType": "comment",
      "contentHtml": "<p>test</p>",
      "renderFailed": false
    },
    "relationships": {
      "discussion": {
        "data": {
          "type": "discussions",
          "id": "108"
        }
      },
      "user": {
        "data": {
          "type": "users",
          "id": "124"
        }
      }
    }
  }
}
```

## API 扩展

若要扩展 REST API 以实现新的应用，请查看开发者文档《API 与数据流》。

每个扩展程序都可自行添加新的端点和属性，因此提供涵盖所有端点的文档较为困难。若要查看所有端点，您可以使用浏览器的开发者工具检查单页应用发起的请求。

## 注意事项

1. **认证要求** - 除 GET 端点外，其他端点均需身份验证
2. **分页** - 列表类端点支持分页，使用 `page[offset]` 和 `page[limit]` 参数
3. **CSRF 保护** - 使用 API 密钥或访问令牌可跳过 CSRF 保护
4. **权限控制** - 响应中的 `can*` 属性表示当前用户是否有相应操作权限
5. **扩展属性** - 部分属性可能来自扩展，如 `fof-upload-*` 属性

## 示例代码

### 使用 Python 请求 API

```python
import requests

# 1. 获取访问令牌
token_response = requests.post(
    'https://flarum.imikufans.cn/api/token',
    json={'identification': '***', 'password': '******'}
)
token_data = token_response.json()
token = token_data['token']

# 2. 使用令牌请求主题帖列表
discussions_response = requests.get(
    'https://flarum.imikufans.cn/api/discussions',
    headers={'Authorization': f'Token {token}'}
)
discussions_data = discussions_response.json()

# 3. 打印主题帖标题
for discussion in discussions_data['data']:
    print(discussion['attributes']['title'])
```

### 使用 JavaScript 请求 API

```javascript
// 1. 获取访问令牌
fetch('https://flarum.imikufans.cn/api/token', {
    method: 'POST',
    headers: {
        'Content-Type': 'application/json'
    },
    body: JSON.stringify({
        identification: '***',
        password: '******'
    })
})
.then(response => response.json())
.then(tokenData => {
    const token = tokenData.token;
    
    // 2. 使用令牌请求主题帖列表
    return fetch('https://flarum.imikufans.cn/api/discussions', {
        headers: {
            'Authorization': `Token ${token}`
        }
    });
})
.then(response => response.json())
.then(discussionsData => {
    // 3. 处理主题帖数据
    console.log(discussionsData);
});
```