import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.SideContent.StuckCharacter.CourtyardStuckCharacterInteraction;
import Peanuts.Foghorn.FoghornStatics;

class ACourtyardStuckCharacter : AHazeSkeletalMeshActor
{
	UPROPERTY(DefaultComponent)
	USphereComponent PlayerBlocker;
	default PlayerBlocker.SphereRadius = 74.f;

	UPROPERTY()
	ACourtyardStuckCharacterInteraction CurrentStuckLocation;
	ACourtyardStuckCharacterInteraction TargetStuckLocation;

	AHazePlayerCharacter ThrownByPlayer;

	UPROPERTY()
	UCastleCourtyardVOBank VOBank;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent StuckKnightAkComp;

	UPROPERTY()
	AHazeActor GuardCaptain;

	UPROPERTY()
	ACourtyardStuckCharacterInteraction CaptainInteractionLocation;

	UHazeAkComponent GuardCaptainHazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StuckKnightIdleAudioEvent;
	
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent GuardCaptainYellEvent;

	private FHazeAudioEventInstance GuardCaptainEventInstance;

	default bRunConstructionScriptOnDrag = true;

	TPerPlayer<int> TimesThrown;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(GuardCaptain != nullptr)
			GuardCaptainHazeAkComp = UHazeAkComponent::GetOrCreate(GuardCaptain);

		PlayerBlocker.AttachToComponent(Mesh, n"Spine2");

		if (CurrentStuckLocation != nullptr)
		{
			CurrentStuckLocation.OnStuckCharacterPlayerCancelled.AddUFunction(this, n"OnPlayerCancelled");
			CurrentStuckLocation.OnStuckCharacterButtonMashComplete.AddUFunction(this, n"LaunchCharacter");

			CurrentStuckLocation.InteractionComp.OnActivated.AddUFunction(this, n"OnInteractionActivated");
			CurrentStuckLocation.InteractionComp.Enable(n"Empty");
			StuckKnightAkComp.HazePostEvent(StuckKnightIdleAudioEvent);

			if(GuardCaptainHazeAkComp != nullptr)
				GuardCaptainEventInstance = GuardCaptainHazeAkComp.HazePostEvent(GuardCaptainYellEvent);
		}		

	}

	UFUNCTION(NotBlueprintCallable)
	private void OnInteractionActivated(UInteractionComponent UsedInteraction, AHazePlayerCharacter Player)
	{
		if (TimesThrown[Player] == 0)
		{
			FName EventName = Player.IsMay() ? n"FoghornDBPlayroomCastleCourtyardStuckCharacterFreeFirst_May" : n"FoghornDBPlayroomCastleCourtyardStuckCharacterFreeFirst_Cody";
			PlayFoghornVOBankEvent(VOBank, EventName);
		}
		else
		{
			FName EventName = Player.IsMay() ? n"FoghornDBPlayroomCastleCourtyardStuckCharacterFreeRepeat_May" : n"FoghornDBPlayroomCastleCourtyardStuckCharacterFreeRepeat_Cody";
			PlayFoghornVOBankEvent(VOBank, EventName);
		}

		FHazePlaySlotAnimationParams Params;
		Params.Animation = CurrentStuckLocation.CharacterAnimations.Struggle;
		Params.bLoop = true;
		Params.BlendTime = CurrentStuckLocation.PlayerAnimations[Player].Enter.GetPlayLength();
		Params.StartTime = CurrentStuckLocation.CharacterAnimations.Struggle.GetPlayLength() - CurrentStuckLocation.PlayerAnimations[Player].Enter.GetPlayLength();
		PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), Params);	
	}

	UFUNCTION()
	void OnPlayerCancelled(AHazePlayerCharacter Player)
	{
		FHazePlaySlotAnimationParams Params;
		Params.Animation = CurrentStuckLocation.CharacterAnimations.MH;
		Params.bLoop = true;
		Params.BlendTime = CurrentStuckLocation.PlayerAnimations[Player].Cancel.GetPlayLength();

		PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), Params);
	}

	UFUNCTION()
	void LaunchCharacter(AHazePlayerCharacter Player)
	{
		ThrownByPlayer = Player;
		TargetStuckLocation = CurrentStuckLocation.TargetInteraction;
		TimesThrown[Player] += 1;

		FHazePointOfInterest PointOfInterest;
		PointOfInterest.Duration = 1.f;
		PointOfInterest.Blend = FHazeCameraBlendSettings(0.4f);
		PointOfInterest.FocusTarget.Actor = this;
		Player.ApplyPointOfInterest(PointOfInterest, this);

		FName EventName = Player.IsMay() ? n"FoghornDBPlayroomCastleCourtyardStuckCharacterThrow_May" : n"FoghornDBPlayroomCastleCourtyardStuckCharacterThrow_Cody";
		PlayFoghornVOBankEvent(VOBank, EventName);

		if(GuardCaptainHazeAkComp != nullptr)
			GuardCaptainHazeAkComp.HazeStopEvent(GuardCaptainEventInstance.PlayingID, 100.f);
	}

	void Landed()
	{
		TargetStuckLocation.CharacterLocation.CharacterLandedNiagaraComp.Activate();
	}

	UFUNCTION()
	void LaunchAnimationComplete()
	{
		if (TimesThrown[ThrownByPlayer] == 1)
		{
			FName EventName = ThrownByPlayer.IsMay() ? n"FoghornDBPlayroomCastleCourtyardStuckCharacterLandFirst_May" : n"FoghornDBPlayroomCastleCourtyardStuckCharacterLandFirst_Cody";
			PlayFoghornVOBankEvent(VOBank, EventName);
		}
		else
		{
			FName EventName = ThrownByPlayer.IsMay() ? n"FoghornDBPlayroomCastleCourtyardStuckCharacterLandRepeat_May" : n"FoghornDBPlayroomCastleCourtyardStuckCharacterLandRepeat_Cody";
			PlayFoghornVOBankEvent(VOBank, EventName);
		}

		if(CurrentStuckLocation == CaptainInteractionLocation && GuardCaptainHazeAkComp != nullptr)
			GuardCaptainHazeAkComp.HazePostEvent(GuardCaptainYellEvent);

		ThrownByPlayer = nullptr;
	}
}