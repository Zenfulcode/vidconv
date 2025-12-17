<script lang="ts">
	import { Folder } from '@lucide/svelte';
	import { Button } from '$lib/components/ui/button';
	import { Input } from '$lib/components/ui/input';
	import { Label } from '$lib/components/ui/label';
	import { Checkbox } from '$lib/components/ui/checkbox';
	import * as RadioGroup from '$lib/components/ui/radio-group';
	import { ScrollArea } from '$lib/components/ui/scroll-area';
	import { converterStore } from '$lib/stores/converter.svelte';
	import { SelectDirectory } from '$lib/wailsjs/go/main/App';

	async function handleSelectDirectory() {
		try {
			const dir = await SelectDirectory();
			if (dir) {
				converterStore.setOutputDirectory(dir);
			}
		} catch (err) {
			console.error('Failed to select directory:', err);
		}
	}

	function handleNamingModeChange(value: string) {
		converterStore.setNamingMode(value as 'original' | 'custom');
	}

	function handleMakeCopiesChange(checked: boolean | 'indeterminate') {
		converterStore.setMakeCopies(checked === true);
	}

	function handleCustomNameChange(index: number, event: Event) {
		const target = event.target as HTMLInputElement;
		converterStore.setCustomName(index, target.value);
	}
</script>

<div class="space-y-6">
	<!-- Output Directory -->
	<div class="space-y-2">
		<Label>Output Directory</Label>
		<div class="flex gap-2">
			<Input
				value={converterStore.outputDirectory}
				placeholder="Select output directory..."
				readonly
				class="flex-1"
			/>
			<Button variant="outline" onclick={handleSelectDirectory}>
				<Folder class="mr-2 h-4 w-4" />
				Browse
			</Button>
		</div>
	</div>

	<!-- File Naming Mode -->
	<div class="space-y-3">
		<Label>Filename Options</Label>
		<RadioGroup.Root value={converterStore.namingMode} onValueChange={handleNamingModeChange}>
			<div class="flex items-center space-x-2">
				<RadioGroup.Item value="original" id="naming-original" />
				<Label for="naming-original" class="font-normal cursor-pointer">
					Keep original filenames
				</Label>
			</div>
			<div class="flex items-center space-x-2">
				<RadioGroup.Item value="custom" id="naming-custom" />
				<Label for="naming-custom" class="font-normal cursor-pointer">
					Use custom filenames
				</Label>
			</div>
		</RadioGroup.Root>
	</div>

	<!-- Custom Names (shown when custom mode is selected) -->
	{#if converterStore.namingMode === 'custom' && converterStore.files.length > 0}
		<div class="space-y-2">
			<Label>Custom Filenames</Label>
			<ScrollArea class="h-[150px] rounded-md border p-3">
				<div class="space-y-2">
					{#each converterStore.files as file, index}
						<div class="flex items-center gap-2">
							<span class="w-8 text-xs text-muted-foreground">{index + 1}.</span>
							<Input
								value={converterStore.customNames[index] || ''}
								placeholder={file.name.replace(file.extension, '')}
								oninput={(e) => handleCustomNameChange(index, e)}
								class="flex-1"
							/>
							<span class="text-xs text-muted-foreground">
								.{converterStore.outputFormat || '???'}
							</span>
						</div>
					{/each}
				</div>
			</ScrollArea>
			<p class="text-xs text-muted-foreground">
				Leave empty to use original filename
			</p>
		</div>
	{/if}

	<!-- Make Copies Option -->
	<div class="flex items-start space-x-3 rounded-lg border p-4">
		<Checkbox
			id="make-copies"
			checked={converterStore.makeCopies}
			onCheckedChange={handleMakeCopiesChange}
		/>
		<div class="space-y-1">
			<Label for="make-copies" class="cursor-pointer">Create copies</Label>
			<p class="text-xs text-muted-foreground">
				{#if converterStore.makeCopies}
					Original files will be preserved. New files will be created in the output directory.
				{:else}
					Original files will be replaced with converted versions.
					<span class="text-destructive font-medium">This cannot be undone!</span>
				{/if}
			</p>
		</div>
	</div>
</div>
