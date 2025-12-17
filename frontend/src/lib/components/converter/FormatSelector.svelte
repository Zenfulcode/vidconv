<script lang="ts">
	import * as Select from '$lib/components/ui/select';
	import { Label } from '$lib/components/ui/label';
	import { converterStore } from '$lib/stores/converter.svelte';
	import { VIDEO_OUTPUT_FORMATS, IMAGE_OUTPUT_FORMATS } from '$lib/types';

	let availableFormats = $derived(
		converterStore.fileType === 'video'
			? VIDEO_OUTPUT_FORMATS
			: converterStore.fileType === 'image'
				? IMAGE_OUTPUT_FORMATS
				: []
	);

	function handleFormatChange(value: string | undefined) {
		if (value) {
			converterStore.setOutputFormat(value);
		}
	}
</script>

<div class="space-y-2">
	<Label for="format-select">Output Format</Label>
	<Select.Root
		type="single"
		value={converterStore.outputFormat}
		onValueChange={handleFormatChange}
		disabled={!converterStore.hasFiles}
	>
		<Select.Trigger id="format-select" class="w-full">
			{#if converterStore.outputFormat}
				<span class="uppercase">{converterStore.outputFormat}</span>
			{:else}
				<span class="text-muted-foreground">Select output format</span>
			{/if}
		</Select.Trigger>
		<Select.Content>
			{#each availableFormats as format}
				<Select.Item value={format}>
					<span class="uppercase">{format}</span>
				</Select.Item>
			{/each}
		</Select.Content>
	</Select.Root>
	{#if converterStore.fileType}
		<p class="text-xs text-muted-foreground">
			Converting {converterStore.files.length}
			{converterStore.fileType} file{converterStore.files.length > 1 ? 's' : ''}
		</p>
	{/if}
</div>
