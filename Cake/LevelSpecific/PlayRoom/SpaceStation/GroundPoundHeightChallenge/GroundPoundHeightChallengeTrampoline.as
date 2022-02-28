import Vino.Movement.Components.FloorJumpCallbackComponent;
import Vino.Checkpoints.Checkpoint;
import Vino.MinigameScore.MinigameComp;
import Cake.LevelSpecific.PlayRoom.SpaceStation.GroundPoundHeightChallenge.GroundPoundHeightChallengeTarget;

class AGroundPoundHeightChallengeTrampoline : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent TrampolineRoot;

	UPROPERTY(DefaultComponent, Attach = TrampolineRoot)
	UStaticMeshComponent TrampolineMesh;

	UPROPERTY(DefaultComponent)
	UMinigameComp MinigameComp;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UHazeCapability> RequiredCapability;

	UPROPERTY()
	ACheckpoint RespawnCheckpoint;

	UPROPERTY()
	AGroundPoundHeightChallengeTarget Target;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FActorJumpedFromDelegate JumpDelegate;
		JumpDelegate.BindUFunction(this, n"JumpedFrom");
		BindOnActorJumpedFrom(this, JumpDelegate);

		Capability::AddPlayerCapabilityRequest(RequiredCapability);

		if (MinigameComp.HudAreaVolumes.Num() > 0)
		{
			for (AVolume Volume : MinigameComp.HudAreaVolumes)
			{
				if (Volume == nullptr)
					return;

				Volume.OnActorBeginOverlap.AddUFunction(this, n"ActorHudAreaBeginOverlap");
				Volume.OnActorEndOverlap.AddUFunction(this, n"ActorHudAreaEndOverlap");
			}
		}
	}

	UFUNCTION()
	void ActorHudAreaBeginOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		
		if (Player == nullptr)
			return;

		MinigameComp.ShowGameHud();
	}

	UFUNCTION()
	void ActorHudAreaEndOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		
		if (Player == nullptr)
			return;

		// MinigameComp.EndGameHud();
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		Capability::RemovePlayerCapabilityRequest(RequiredCapability);
	}

	UFUNCTION(NotBlueprintCallable)
	void JumpedFrom(AHazePlayerCharacter Player, UPrimitiveComponent Comp)
	{
		Player.SetCapabilityAttributeObject(n"GroundPoundTrampoline", this);
		Player.SetCapabilityActionState(n"GroundPoundChallenge", EHazeActionState::Active);
	}

	void UpdatePlayerScore(AHazePlayerCharacter Player, float Score)
	{
		MinigameComp.SetScore(Player, Score);
	}
}