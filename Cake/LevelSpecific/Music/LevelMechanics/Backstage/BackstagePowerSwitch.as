import Vino.Interactions.InteractionComponent;
import Vino.Interactions.DoubleInteractComponent;
import Peanuts.Audio.AudioStatics;
import Vino.Triggers.VOBarkTriggerComponent;

event void FOnPlayerStartedInteraction(AHazePlayerCharacter Player);
event void FOnDoubleInteractedStarted();
event void FBackstagePowerSwitchSignature();

class ABackstagePowerSwitch : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshBase;

	UPROPERTY(DefaultComponent, Attach = MeshBase)
	UPointLightComponent PointLight;
	default PointLight.Mobility = EComponentMobility::Movable;

	UPROPERTY(DefaultComponent, Attach = MeshBase)
	UStaticMeshComponent MeterArmMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent HandleRoot;

	UPROPERTY(DefaultComponent, Attach = HandleRoot)
	UStaticMeshComponent HandleMesh;

	UPROPERTY(DefaultComponent, Attach = AttachComponent01)
	UInteractionComponent InteractionComp01;

	UPROPERTY(DefaultComponent, Attach = AttachComponent02)
	UInteractionComponent InteractionComp02;

	UPROPERTY(DefaultComponent, Attach = HandleMesh)
	USceneComponent AttachComponent01;

	UPROPERTY(DefaultComponent, Attach = HandleMesh)
	USceneComponent AttachComponent02;

	UPROPERTY(DefaultComponent)
	UDoubleInteractComponent DoubleInteract;

	UPROPERTY(DefaultComponent, Attach = InteractionComp01)
	USkeletalMeshComponent EditorSkelMesh01;
	default EditorSkelMesh01.bHiddenInGame = true;
	default EditorSkelMesh01.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = InteractionComp02)
	USkeletalMeshComponent EditorSkelMesh02;
	default EditorSkelMesh02.bHiddenInGame = true;
	default EditorSkelMesh02.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = MeshBase)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(DefaultComponent)
	UVOBarkTriggerComponent VOBarkTriggerComponent;
	default VOBarkTriggerComponent.bRepeatForever = true;
	default VOBarkTriggerComponent.RetriggerDelays.Add(2.f);
	default VOBarkTriggerComponent.bTriggerLocally = true;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OnePlayerOnSwitchAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StoppedUsingSwitchAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DoubleInteractStartedAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SwitchActivatedAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SwitchBuzzAudioEvent;

	UPROPERTY()
	FBackstagePowerSwitchSignature SwitchActivatedEvent;
	UPROPERTY()
	FOnDoubleInteractedStarted OnDoubleInteractedStarted;
	UPROPERTY()
	FOnPlayerStartedInteraction OnPlayerStartedInteraction; 

	UPROPERTY()
	UAnimSequence CodyAnimation;
	
	UPROPERTY()
	UAnimSequence MayAnimation;

	FVector GreenEmissive = FVector(0.f, 150.f, 16.f);
	FVector RedEmissive = FVector(150.f, 26.f, 0.f);

	UPROPERTY()
	UMaterialInterface LampMatOn;

	UPROPERTY()
	UMaterialInterface LampMatOff;

	UPROPERTY()
	float InterpSpeed = 2.f;

	UPROPERTY()
	bool bStartDisabled = false;

	UPROPERTY()
	bool bPlayersEverAllowedToCancel = true;

	UAnimSequence Animation;

	TArray<AHazePlayerCharacter> PlayersOnHandle;

	float StartingPitch = -30.f;
	float OnePlayerPitch = -10.f;
	float TwoPlayersPitch = 70.f;

	float MeterStartingRoll = -45.f;
	float MeterOnePlayterRoll = -20.f;
	float MeterTwoPlayersRoll = 45.f;

	bool bSwitchHasBeenActivated = false;

	private TPerPlayer<bool> BarkReady;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp01.OnActivated.AddUFunction(this, n"SwitchInteractedWith");
		InteractionComp02.OnActivated.AddUFunction(this, n"SwitchInteractedWith");
		DoubleInteract.OnTriggered.AddUFunction(this, n"BothPlayersSwitch");

		MeshBase.SetVectorParameterValueOnMaterialIndex(12, n"EmissiveColor", FVector::ZeroVector);

		HazeAkComp.HazePostEvent(SwitchBuzzAudioEvent);

		if (bStartDisabled)
			SetPowerSwitchEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		AttachComponent01.SetWorldRotation(FRotator(0.f, AttachComponent01.WorldRotation.Yaw, AttachComponent01.WorldRotation.Roll));
		AttachComponent02.SetWorldRotation(FRotator(0.f, AttachComponent02.WorldRotation.Yaw, AttachComponent02.WorldRotation.Roll));

		if (bSwitchHasBeenActivated)
			return;
		
		float TargetPitch;
		float MeterTargetRoll;
		
		switch (PlayersOnHandle.Num())
		{
			case 0:
				TargetPitch = StartingPitch;
				MeterTargetRoll = MeterStartingRoll;
				break;

			case 1:
				TargetPitch = OnePlayerPitch;
				MeterTargetRoll = MeterOnePlayterRoll;
				break;

			case 2:
				TargetPitch = TwoPlayersPitch;
				MeterTargetRoll = MeterTwoPlayersRoll;
				break;
		}
		
		HandleRoot.SetRelativeRotation(FRotator(FMath::FInterpTo(HandleRoot.RelativeRotation.Pitch, TargetPitch, DeltaTime, InterpSpeed), 0.f, 0.f));
		MeterArmMesh.SetRelativeRotation(FRotator(0.f, 0.f, FMath::FInterpTo(MeterArmMesh.RelativeRotation.Roll, MeterTargetRoll, DeltaTime, InterpSpeed)));
	}

	UFUNCTION()
	void SwitchInteractedWith(UInteractionComponent Comp, AHazePlayerCharacter Player)
	{
		if (PlayersOnHandle.AddUnique(Player))
		{
			VOBarkReady(Player);
			OnPlayerStartedInteraction.Broadcast(Player);

			Player.AddCapability(n"BackstagePowerSwitchCapability");
			Player.SetCapabilityAttributeObject(n"InteractionComponent", Comp);
			Player.SetCapabilityAttributeObject(n"BackstagePowerSwitch", this);
			
			Animation = Player == Game::GetCody() ? CodyAnimation : MayAnimation;
			Player.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), Animation, true);

			Comp.Disable(n"UsingSwitch");

			if(PlayersOnHandle.Num() == 1)
			{
				HazeAudio::SetPlayerPanning(HazeAkComp, Player);
				HazeAkComp.HazePostEvent(OnePlayerOnSwitchAudioEvent);
			}

			DoubleInteract.StartInteracting(Player);			
		}		
	}

	// Used only once in MusicTechWall where we need to disable SplineLockMovement before the JumpTo.
	// Therefore calling a JumpTo from LevelBP and calling this function when the JumpTo is completed.
	UFUNCTION(NetFunction)
	void NetSwitchInteractedFromOtherSource(AHazePlayerCharacter Player)
	{
		if (PlayersOnHandle.AddUnique(Player))
		{
			UInteractionComponent Comp = Player == Game::GetCody() ? InteractionComp02 : InteractionComp01; 
			VOBarkReady(Player);
			OnPlayerStartedInteraction.Broadcast(Player);

			Player.AddCapability(n"BackstagePowerSwitchCapability");
			Player.SetCapabilityAttributeObject(n"InteractionComponent", Comp);
			Player.SetCapabilityAttributeObject(n"BackstagePowerSwitch", this);
			
			Animation = Player == Game::GetCody() ? CodyAnimation : MayAnimation;
			Player.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), Animation, true);

			if(PlayersOnHandle.Num() == 1)
			{
				HazeAudio::SetPlayerPanning(HazeAkComp, Player);
				HazeAkComp.HazePostEvent(OnePlayerOnSwitchAudioEvent);
			}

			DoubleInteract.StartInteracting(Player);	
		}
	}

	UFUNCTION()
	void BothPlayersSwitch()
	{
		if (PlayersOnHandle.Num() == 2)
		{
			System::SetTimer(this, n"SwitchActivated", 1.5f, false);
			OnDoubleInteractedStarted.Broadcast();
			HazeAkComp.HazePostEvent(DoubleInteractStartedAudioEvent);
		}
		else
		{
			ensure(false);
		}
	}

	UFUNCTION()
	void SetPowerSwitchEnabled(bool bEnabled)
	{
		if (!bEnabled)
		{
			InteractionComp01.Disable(n"EnableSwitch");
			InteractionComp02.Disable(n"EnableSwitch");
		}
		else
		{
			InteractionComp01.Enable(n"EnableSwitch");
			InteractionComp02.Enable(n"EnableSwitch");
		}
	}

	UFUNCTION()
	void SwitchActivated()
	{
		VOBarkCompleted();
		bSwitchHasBeenActivated = true;
		HandleRoot.SetRelativeRotation(FRotator(TwoPlayersPitch, 0.f, 0.f));

		MeshBase.SetVectorParameterValueOnMaterialIndex(12, n"EmissiveColor", GreenEmissive);
		MeshBase.SetVectorParameterValueOnMaterialIndex(11, n"EmissiveColor", FVector::ZeroVector);

		SwitchActivatedEvent.Broadcast();
		HazeAkComp.HazePostEvent(SwitchActivatedAudioEvent);
		PointLight.LightColor = FLinearColor::Green;
		
		for (AHazePlayerCharacter Player : PlayersOnHandle)
		{
			Player.SetCapabilityAttributeObject(n"InteractionComponent", nullptr);
		}
	}

	void PlayerStoppedUsingSwitch(AHazePlayerCharacter Player)
	{
		VOBarkCancel(Player);
		DoubleInteract.CancelInteracting(Player);
		PlayersOnHandle.Remove(Player);
		Player.StopAllSlotAnimations();

		if(!bSwitchHasBeenActivated)
		{
			HazeAudio::SetPlayerPanning(HazeAkComp, Player);
			HazeAkComp.HazePostEvent(StoppedUsingSwitchAudioEvent);
		}
	}

	void SetInteractionPointEnabled(UInteractionComponent InteractionComp)
	{
		InteractionComp.Enable(n"UsingSwitch");
	}

	UFUNCTION(NotBlueprintCallable)
	void VOBarkReady(AHazePlayerCharacter Player)
	{
		BarkReady[Player.Player] = true;

		VOBarkTriggerComponent.SetBarker(Player);

		if (BarkReady[Player.OtherPlayer.Player])
			VOBarkTriggerComponent.OnEnded();
		else
			VOBarkTriggerComponent.OnStarted();
	}

	UFUNCTION(NotBlueprintCallable)
	void VOBarkCancel(AHazePlayerCharacter Player)
	{
		BarkReady[Player.Player] = false;

		VOBarkTriggerComponent.SetBarker(Player.OtherPlayer);

		if (BarkReady[Player.OtherPlayer.Player])
			VOBarkTriggerComponent.OnStarted(); 
		else
			VOBarkTriggerComponent.OnEnded();
	}

	UFUNCTION(NotBlueprintCallable)
	void VOBarkCompleted()
	{
		VOBarkTriggerComponent.TriggerCount = VOBarkTriggerComponent.MaxTriggerCount;
		VOBarkTriggerComponent.bRepeatForever = false;
		VOBarkTriggerComponent.OnEnded();
	}
}