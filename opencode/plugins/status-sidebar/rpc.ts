import { Rpc } from "@opencode/plugin/rpc"

const metric = {
  type: "object",
  properties: {
    label: { type: "string" },
    percent: { type: "number" },
    value: { type: "string" },
    resetAt: { type: "number" },
  },
  required: ["label"],
  additionalProperties: false,
} as const

export const StatusSidebarRpc = Rpc.define({
  id: "status-sidebar",
  methods: {
    usage: {
      input: {
        type: "object",
        additionalProperties: false,
      },
      output: {
        type: "object",
        properties: {
          providers: {
            type: "array",
            items: {
              type: "object",
              properties: {
                id: { type: "string" },
                name: { type: "string" },
                auth: { type: "string" },
                metrics: { type: "array", items: metric },
              },
              required: ["id", "name", "auth", "metrics"],
              additionalProperties: false,
            },
          },
        },
        required: ["providers"],
        additionalProperties: false,
      },
    },
  },
  events: {},
})
