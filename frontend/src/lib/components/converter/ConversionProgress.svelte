<script lang="ts">
	import { Loader2, CheckCircle2, XCircle } from '@lucide/svelte';
	import { Progress } from '$lib/components/ui/progress';
	import { Card, CardContent, CardHeader, CardTitle } from '$lib/components/ui/card';
	import { Badge } from '$lib/components/ui/badge';
	import { ScrollArea } from '$lib/components/ui/scroll-area';
	import { converterStore } from '$lib/stores/converter.svelte';
	import { formatDuration } from '$lib/types';

	let currentFileName = $derived(
		converterStore.currentProgress?.inputPath.split('/').pop() ||
			converterStore.currentProgress?.inputPath.split('\\').pop() ||
			''
	);
</script>

<Card class="w-full">
	<CardHeader class="pb-3">
		<div class="flex items-center justify-between">
			<CardTitle class="text-lg">Conversion Progress</CardTitle>
			{#if converterStore.isConverting}
				<Badge variant="secondary" class="animate-pulse">
					<Loader2 class="mr-1 h-3 w-3 animate-spin" />
					Converting...
				</Badge>
			{:else if converterStore.lastResult}
				{#if converterStore.lastResult.failCount === 0}
					<Badge variant="default" class="bg-green-600">
						<CheckCircle2 class="mr-1 h-3 w-3" />
						Complete
					</Badge>
				{:else}
					<Badge variant="destructive">
						<XCircle class="mr-1 h-3 w-3" />
						{converterStore.lastResult.failCount} failed
					</Badge>
				{/if}
			{/if}
		</div>
	</CardHeader>
	<CardContent class="space-y-4">
		{#if converterStore.isConverting}
			<!-- Overall progress -->
			<div class="space-y-2">
				<div class="flex justify-between text-sm">
					<span>Overall Progress</span>
					<span>{Math.round(converterStore.overallProgress)}%</span>
				</div>
				<Progress value={converterStore.overallProgress} class="h-2" />
			</div>

			<!-- Current file -->
			{#if converterStore.currentProgress}
				<div class="space-y-2">
					<div class="flex justify-between text-sm">
						<span class="truncate text-muted-foreground">{currentFileName}</span>
						<span>{Math.round(converterStore.currentProgress.progress)}%</span>
					</div>
					<Progress value={converterStore.currentProgress.progress} class="h-1" />
				</div>
			{/if}
		{:else if converterStore.lastResult}
			<!-- Results summary -->
			<div class="grid grid-cols-3 gap-4 text-center">
				<div class="rounded-lg bg-muted p-3">
					<p class="text-2xl font-bold">{converterStore.lastResult.totalFiles}</p>
					<p class="text-xs text-muted-foreground">Total</p>
				</div>
				<div class="rounded-lg bg-green-500/10 p-3">
					<p class="text-2xl font-bold text-green-600">{converterStore.lastResult.successCount}</p>
					<p class="text-xs text-muted-foreground">Success</p>
				</div>
				<div class="rounded-lg bg-destructive/10 p-3">
					<p class="text-2xl font-bold text-destructive">{converterStore.lastResult.failCount}</p>
					<p class="text-xs text-muted-foreground">Failed</p>
				</div>
			</div>

			<p class="text-center text-sm text-muted-foreground">
				Completed in {formatDuration(converterStore.lastResult.totalDuration)}
			</p>

			<!-- Detailed results -->
			{#if converterStore.lastResult.results.length > 0}
				<ScrollArea class="h-[150px] rounded-md border">
					<div class="p-3 space-y-2">
						{#each converterStore.lastResult.results as result}
							{@const fileName = result.inputPath.split('/').pop() || result.inputPath.split('\\').pop()}
							<div
								class="flex items-center justify-between rounded p-2 text-sm {result.success
									? 'bg-green-500/5'
									: 'bg-destructive/5'}"
							>
								<div class="flex items-center gap-2 overflow-hidden">
									{#if result.success}
										<CheckCircle2 class="h-4 w-4 flex-shrink-0 text-green-600" />
									{:else}
										<XCircle class="h-4 w-4 flex-shrink-0 text-destructive" />
									{/if}
									<span class="truncate">{fileName}</span>
								</div>
								{#if result.success}
									<span class="text-xs text-muted-foreground">{formatDuration(result.duration)}</span
									>
								{:else}
									<span class="text-xs text-destructive truncate max-w-[150px]"
										>{result.errorMessage}</span
									>
								{/if}
							</div>
						{/each}
					</div>
				</ScrollArea>
			{/if}
		{:else}
			<p class="text-center text-sm text-muted-foreground py-4">
				No conversion in progress
			</p>
		{/if}
	</CardContent>
</Card>
