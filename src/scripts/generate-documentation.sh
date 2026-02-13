#!/bin/bash


### Variables.

export name=$(yq .name ./src/model/*.linkml.yml | tr '-' '_')
export title=$(yq .title ./src/model/*.linkml.yml)
export version=$(yq .version ./src/model/*.linkml.yml)


### Functions.

function _clean() {
    echo "Cleaning up…"
    echo
    if [ -d output ]; then
        rm -rf output
    fi
    echo "… OK."
    echo
}

function _generate-json-schema {
    echo "Generating JSON Schema…"
    mkdir -p $OUTDIR/schemas/json-schema
    echo
    gen-json-schema \
        --not-closed \
        src/model/$name.linkml.yml \
        > output/schemas/json-schema/$name.json_schema.json
    echo "… OK."
    echo
    echo "Generated JSON Schema at: output/schemas/json-schema/$name.json_schema.json"
    echo
}

function build() {
    echo "Generating documentation…"
    _clean
    echo
    mkdir -p $OUTDIR/docs/adoc
    cp -r src/docs/* $OUTDIR/docs/adoc
    yq -i '.version = env(version)' $OUTDIR/docs/adoc/antora.yml
    yq -i '.title = env(title)' $OUTDIR/docs/adoc/antora.yml
    echo
    echo "Generating schema documentation…"
    echo
    mkdir -p "$OUTDIR/docs/adoc/modules/schema"
    python -m linkml_asciidoc_generator.main \
        -o $OUTDIR/docs/adoc/modules/schema \
        -t /opt/dataproducten/templates \
        --render-diagrams \
        src/model/$name.linkml.yml
    echo "Adding schema documentation to nav…"
    yq -i '.nav += ["modules/schema/nav.adoc"]' $OUTDIR/docs/adoc/antora.yml
    echo
    echo -e "Generating artifacts…"
    for schema in $(yq .annotations.additional_schemas src/model/*.linkml.yml); do \
        if [ $schema == "json-schema" ]; then
            _generate-json-schema
            cp $OUTDIR/schemas/json-schema/$name.json_schema.json $OUTDIR/docs/adoc/modules/schema/attachments/
        fi
        cp -r $OUTDIR/schemas/json-schema/$name.json_schema.json $OUTDIR/docs/adoc/modules/schema/attachments/; \
        echo -e "To reference use:\n\txref:schema:attachment\$$schema[]"; \
    done
    echo -e "Copy examples (JSON) to schema documentation…"
    for example in src/examples/*.yml; do \
        example_name=$(basename $example); \
        gen-linkml-profile  \
            convert \
            "$example" \
            --out "$OUTDIR/docs/adoc/modules/schema/attachments/${example_name%.*}.json"; \
        echo -e "To reference use:\n\txref:schema:attachment\$${example_name%.*}.json[]"; \
    done
    echo
}


### Main

build
