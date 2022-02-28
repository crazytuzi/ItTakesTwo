class ACourtyardStuckCharacterLocation : AHazeSkeletalMeshActor
{
	UPROPERTY(DefaultComponent)
	UNiagaraComponent CharacterLandedNiagaraComp;
	default CharacterLandedNiagaraComp.SetAutoActivate(false);

	default Mesh.bHiddenInGame = true;
}