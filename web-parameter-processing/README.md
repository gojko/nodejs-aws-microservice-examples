This example shows how to extract request parameters from Api Gateway requests without having to define models.

API Gateway templates are processed using Java, so Java Hashmap methods such as `keySet` and `values` are available,
but they don't render well into JSON. The templates are processed using the [Velocity Template Language](
http://velocity.apache.org/engine/devel/vtl-reference-guide.html
), so with a bit of [templating](json-templates/escaped-params.json), they can get 
extracted into a generic JSON key-value map.

For more information on mapping, see the [API Gateway Template Mapping Reference](http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-mapping-template-reference.html).
