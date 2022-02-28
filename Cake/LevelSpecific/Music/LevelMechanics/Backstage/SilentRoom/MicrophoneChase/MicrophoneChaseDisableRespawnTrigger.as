
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.MicrophoneChase.MicrophoneChaseManager;
class AMicrophoneChaseDisableRespawnTrigger : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBoxComponent BoxCollision;
	default BoxCollision.CollisionProfileName = n"PlayerCharacterOverlapOnly";
	default BoxCollision.bHiddenInGame = true;
#if EDITOR
	default BoxCollision.LineThickness = 20.f;
	default BoxCollision.ShapeColor = FColor::Purple;
#endif

	UPROPERTY()
	AMicrophoneChaseManager ChaseManager;

	bool bHasTriggered = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BoxCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlap");
	}

	UFUNCTION()
	void OnOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr || bHasTriggered)
			return;

		if (!Player.HasControl())
			return;

		ChaseManager.SetRespawnForPlayersEnabled(false);
		bHasTriggered = true;
	}

	UFUNCTION(CallInEditor)
	void SetChaseManagerRef()
	{
		if (ChaseManager != nullptr)
			return;

		TArray<AActor> Array;
		Gameplay::GetAllActorsOfClass(AMicrophoneChaseManager::StaticClass(), Array);
		ChaseManager = Cast<AMicrophoneChaseManager>(Array[0]);
	}
}