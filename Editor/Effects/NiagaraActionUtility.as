/*
 * Action Utility to aid in replacing existing Niagara Actors with Haze Niagara Actors.
 */

class UNiagaraActionUtility : UActorActionUtility
{
	UFUNCTION(BlueprintOverride)
	UClass GetSupportedClass() const
	{
		return ANiagaraActor::StaticClass();
	}

	UFUNCTION(CallInEditor, Category = "Convert Niagara To Haze")
	void ConvertToHazeNiagaraActor()
	{
		TArray<AActor> NiagaraActors;
		TArray<UNiagaraSystem> NiagaraSystems;
		for (AActor Actor : EditorUtility::GetSelectionSet())
		{
			ANiagaraActor NiagaraActor = Cast<ANiagaraActor>(Actor);
			if(NiagaraActor == nullptr)
				continue;

			NiagaraActors.Add(Actor);

			UActorComponent Component = NiagaraActor.GetComponentByClass(UNiagaraComponent::StaticClass());
			UNiagaraComponent NiagaraComponent = Cast<UNiagaraComponent>(Component);

			NiagaraSystems.Add(NiagaraComponent.GetAsset());
		}

		// TODO: Unsure what the last argument does, so just passing it an empty string for now
		TArray<AActor> ConvertedActors = EditorLevel::ConvertActors(NiagaraActors, AHazeNiagaraActor::StaticClass(), "");

		for (int i = 0; i < ConvertedActors.Num(); i++)
		{
			UActorComponent Component = ConvertedActors[i].GetComponentByClass(UNiagaraComponent::StaticClass());
			UNiagaraComponent NiagaraComponent = Cast<UNiagaraComponent>(Component);

			NiagaraComponent.SetAsset(NiagaraSystems[i]);
		}
	}
}