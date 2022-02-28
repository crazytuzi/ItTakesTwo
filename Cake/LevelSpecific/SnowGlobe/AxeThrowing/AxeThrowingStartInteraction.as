import Vino.Interactions.InteractionComponent;

class AAxeThrowingStartInteraction : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(Category = "Setup")
	EHazePlayer TargetPlayer;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent IciclePop;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent IcicleSpawnPoint;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent IcicleAppear;
	default IcicleAppear.SetAutoActivate(false);

	UFUNCTION()
	void ActivateIcicleNiagara(AHazePlayerCharacter Player)
	{
		IcicleAppear.Activate();
		Player.PlayerHazeAkComp.HazePostEvent(IciclePop);
	}
}