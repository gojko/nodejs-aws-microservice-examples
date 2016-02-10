/*global exports, console*/
exports.handler = function (event, context) {
	'use strict';
	var files = event.Records || [];
	files.forEach(function (eventRecord) {
		if (eventRecord.eventSource === 'aws:s3' && eventRecord.s3) {
			console.log('processing', eventRecord.s3.object.key, ' from ', eventRecord.s3.bucket.name);
		} else {
			context.fail('unsupported event source', eventRecord.eventSource);
		}
	});
	context.succeed();
};
