import Peanuts.Triggers.PlayerTrigger;
event void FTimeBubbleEvent();
import Cake.LevelSpecific.Clockwork.Bird.ClockworkBirdFlyingComponent;

class AClockworkForestTimeBubble : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent BubbleMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USphereComponent BubbleCollision;

	UPROPERTY()
	FTimeBubbleEvent OnTimeBubbleDisabled;

	UPROPERTY()
	TArray<APlayerTrigger> AdditionalTriggers;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent BombEnterBubbleEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent BirdEnterBubbleEvent;

	bool bBubbleDisabled = false;

	bool bLeftBeamDisabled = false;
	bool bRightBeamDisabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BubbleCollision.OnComponentBeginOverlap.AddUFunction(this, n"EnterBubble");
		BubbleCollision.OnComponentEndOverlap.AddUFunction(this, n"ExitBubble");

		for (APlayerTrigger Trigger : AdditionalTriggers)
		{
			Trigger.OnPlayerEnter.AddUFunction(this, n"PlayerEnteredExternalTrigger");
			Trigger.OnPlayerLeave.AddUFunction(this, n"PlayerExitedExternalTrigger");
		}

		AddCapability(n"ClockworkForestTimeBubbleAudioCapability");
	}

	UFUNCTION()
	void PlayerEnteredExternalTrigger(AHazePlayerCharacter Player)
	{
		PlayerEnteredBubble(Player);
	}

	UFUNCTION()
	void PlayerExitedExternalTrigger(AHazePlayerCharacter Player)
	{
		ExitBubble(BubbleCollision, Player, Player.CapsuleComponent, 0);
	}

	void PlayerEnteredBubble(AHazePlayerCharacter Player)
	{
		if (bBubbleDisabled)
			return;

		if (!Player.HasControl())
			return;

		auto FlyingComp = UClockworkBirdFlyingComponent::Get(Player);
		AClockworkBird Bird;
		if (FlyingComp != nullptr && FlyingComp.MountedBird != nullptr)
			Bird = FlyingComp.MountedBird;

		NetEnterBubble(Player, Bird);
	}


	UFUNCTION(NotBlueprintCallable)
	void EnterBubble(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		PlayerEnteredBubble(Player);
	}

	UFUNCTION(NetFunction)
	private void NetEnterBubble(AHazePlayerCharacter Player, AClockworkBird Bird)
	{
		if (Bird != nullptr)
		{
			Bird.SetCapabilityActionState(n"AudioEnteredForcefield", EHazeActionState::ActiveForOneFrame);
			SetCapabilityAttributeObject(n"Bubble_AudioEnteredForcefield", Bird);
		}			
			
		BP_EnterBubble(Player, Bird);
	}

	UFUNCTION(NotBlueprintCallable)
    void ExitBubble(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		if (bBubbleDisabled)
			return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (!Player.HasControl())
			return;
		
		auto FlyingComp = UClockworkBirdFlyingComponent::Get(Player);
		AClockworkBird Bird;
		if(FlyingComp != nullptr && FlyingComp.MountedBird != nullptr)
			Bird = FlyingComp.MountedBird;

		NetExitBubble(Player, Bird);
    }

	UFUNCTION(NetFunction)
	private void NetExitBubble(AHazePlayerCharacter Player, AClockworkBird Bird)
	{
		if (Bird != nullptr)
		{
			Bird.SetCapabilityActionState(n"AudioExitedForcefield", EHazeActionState::ActiveForOneFrame);
			SetCapabilityAttributeObject(n"Bubble_AudioExitedForcefield", Bird);
		}
		BP_ExitBubble(Player, Bird);
	}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void BP_EnterBubble(AHazePlayerCharacter Player, AClockworkBird Bird) {}

	UFUNCTION(BlueprintEvent)
	void BP_ExitBubble(AHazePlayerCharacter Player, AClockworkBird Bird) {}

	UFUNCTION()
	void DisableLeftBeam()
	{
		
		bLeftBeamDisabled = true;
		// BubbleMesh.SetScalarParameterValueOnMaterialIndex(2, n"Opacity", 0.f);
		if (bRightBeamDisabled)
			DisableBubble();
	}

	UFUNCTION()
	void DisableRightBeam()
	{
		bRightBeamDisabled = true;
		// BubbleMesh.SetScalarParameterValueOnMaterialIndex(1, n"Opacity", 0.f);
		if (bLeftBeamDisabled)
			DisableBubble();
	}

	void DisableBubble()
	{
		if (bBubbleDisabled)
			return;

		// BubbleMesh.SetScalarParameterValueOnMaterialIndex(0, n"Opacity", 0.f);
		bBubbleDisabled = true;
		OnTimeBubbleDisabled.Broadcast();
	}
}