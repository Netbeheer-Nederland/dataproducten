const fs = require('fs')
const path = require('path')


module.exports.register = function () {
  this.once('contentAggregated', ({ contentAggregate, playbook }) => {
    for (const { origins } of contentAggregate) {
      for (const origin of origins) {
        const outDir = path.resolve("./output")

        let collector = {
          run: {
            command: `/opt/dataproducten/generate-documentation.sh`,
            env: [{ name: "OUTDIR",
                    value: outDir}]
          },
          scan: {
            clean: true,
            dir: path.join(outDir, "docs/adoc")
          }

        }
        Object.assign((origin.descriptor.ext ??= {}), { collector })
      }
    }
  })
}
