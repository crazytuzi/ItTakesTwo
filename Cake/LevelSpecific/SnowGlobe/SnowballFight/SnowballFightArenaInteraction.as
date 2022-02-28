import Vino.Interactions.InteractionComponent;
// import Cake.LevelSpecific.SnowGlobe.SnowballFight.SnowballFightArenaVolume;
import Vino.Interactions.DoubleInteractionActor;

class ASnowballFightArenaInteraction : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent InteractRoot;
	
	UPROPERTY(Category = "Setup")
	EHazePlayer TargetPlayer;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent GlowOverlapTrigger;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000.f;

	bool bIsGameActive;

	UPROPERTY(Category = "AudioEvents")
	UAkAudioEvent SmallLightUpAudioEvent;

	UPROPERTY(Category = "AudioEvents")
	UAkAudioEvent FullLightUpAudioEvent;

	UPROPERTY(Category = "AudioEvents")
	UAkAudioEvent CancelOutAudioEvent;

	UPROPERTY(Category = "AudioEvents")
	UAkAudioEvent SmallLightOffAudioEvent;

	UPROPERTY()
	bool MayInteract = true; 

	bool PlayerInRange = false;

	UPROPERTY(Category = "InteractionLights")
	float HardnessInactive = 0;
	UPROPERTY(Category = "InteractionLights")
	float RadiusInactive = 0;
	UPROPERTY(Category = "InteractionLights")
	float HardnessOverlap = -1;
	UPROPERTY(Category = "InteractionLights")
	float RadiusOverlap = 120;
	UPROPERTY(Category = "InteractionLights")
	float HardnessActive = 1;
	UPROPERTY(Category = "InteractionLights")
	float RadiusActive = 480;

	UPROPERTY(Category = "InteractionLights")
	FHazeTimeLike OverlapTimelike;
	UPROPERTY(Category = "InteractionLights")
	FHazeTimeLike InteractTimelike;

	AHazePlayerCharacter InteractingPlayer;

	UMaterialInstanceDynamic MaterialInstance;
	bool PlayerInteracting = false;

	float EnableTime;
	float DefaultEnableTime = 0.5f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FHazeTriggerCondition Condition;
		Condition.Delegate.BindUFunction(this, n"InteractionCondition");
		
		MaterialInstance = MeshComp.CreateDynamicMaterialInstance(0);

		MaterialInstance.SetScalarParameterValue(n"Hardness", 0.f);
		MaterialInstance.SetScalarParameterValue(n"Radius", 0.f);

		GlowOverlapTrigger.OnComponentBeginOverlap.AddUFunction(this, n"OnBeginOverlap");
		GlowOverlapTrigger.OnComponentEndOverlap.AddUFunction(this, n"OnEndOverlap");

		OverlapTimelike.BindUpdate(this, n"OnOverlapUpdate");
		InteractTimelike.BindUpdate(this, n"OnInteractUpdate");
	}

	UFUNCTION()
	bool InteractionCondition(UHazeTriggerComponent Trigger, AHazePlayerCharacter Player)
	{
		if(Player.MovementState.GroundedState != EHazeGroundedState::Grounded)
			return false;
		else
			return true;
	}

	UFUNCTION()
	void OnInteracted(AHazePlayerCharacter Player)
	{
		// InteractComp.Disable(n"InUse");

		InteractingPlayer = Player;

		Player.PlayerHazeAkComp.HazePostEvent(FullLightUpAudioEvent, n"LightUpAudioEvent");

		PlayerInteracting = true;

		if(OverlapTimelike.IsPlaying())
			OverlapTimelike.Stop();
	
		InteractTimelike.Play();
	}

	void OnDeactivatedInteraction(AHazePlayerCharacter Player)
	{
		Player.PlayerHazeAkComp.HazePostEvent(CancelOutAudioEvent, n"CancelOutAudioEvent");
		
		// if(!bIsGameActive)
		// 	EnableTime = DefaultEnableTime;

		PlayerInteracting = false;
		InteractingPlayer = nullptr;

		if(OverlapTimelike.IsPlaying())
			OverlapTimelike.Stop();

		InteractTimelike.Reverse();
	}

	// UFUNCTION()
	// void CancelInteract()
	// {
	// 	if(InteractingPlayer != nullptr)
	// 		OnDeactivatedInteraction(InteractingPlayer);
	// }

	UFUNCTION()
	void ReenableInteractions()
	{
		OverlapTimelike.SetNewTime(0.f);

		if(PlayerInRange)
			OverlapTimelike.PlayFromStart();
	}

	//Should keep count if player is in even during gameplay so if finished ontop overlap should play properly on game end.

	UFUNCTION()
	void OnBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		if(bIsGameActive)
		{
			PlayerInRange = true;
			return;
		}

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if(Player != nullptr)
		{
			if(MayInteract && Player.IsMay())
			{
				if(PlayerInteracting)
				{
					return;
				}
				else
				{
					OverlapTimelike.Play();
					Player.PlayerHazeAkComp.HazePostEvent(SmallLightUpAudioEvent, n"SmallLightUpAudioEvent");
				}
			}
			else if(!MayInteract && Player.IsCody())
			{
				if(PlayerInteracting)
				{
					return;
				}
				else
				{
					OverlapTimelike.Play();
					Player.PlayerHazeAkComp.HazePostEvent(SmallLightUpAudioEvent, n"SmallLightUpAudioEvent");
				}
			}

			PlayerInRange = true;
		}
	}

	UFUNCTION()
	void OnEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{
		if(bIsGameActive)
		{
			PlayerInRange = false;
			return;
		}
		
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if(Player != nullptr)
		{
			if(MayInteract && Player.IsMay())
			{
				if(PlayerInteracting)
				{
					return;
				}
				else
				{
					OverlapTimelike.Reverse();
					Player.PlayerHazeAkComp.HazePostEvent(SmallLightOffAudioEvent, n"SmallLightUpAudioEvent");
				}
			}
			else if(!MayInteract && Player.IsCody())
			{
				if(PlayerInteracting)
				{
					return;
				}
				else
				{
					Player.PlayerHazeAkComp.HazePostEvent(SmallLightOffAudioEvent, n"SmallLightUpAudioEvent");
					OverlapTimelike.Reverse();
				}
			}

			PlayerInRange = false;
		}
	}

	UFUNCTION()
	void OnOverlapUpdate(float Value)
	{
		float NewHardness = HardnessOverlap * Value;
		float NewRadius = RadiusOverlap * Value;

		MaterialInstance.SetScalarParameterValue(n"Hardness", NewHardness);
		MaterialInstance.SetScalarParameterValue(n"Radius", NewRadius);
	}

	UFUNCTION()
	void OnInteractUpdate(float Value)
	{
		float StartHardness = 0.f;
		float StartRadius = 0.f;

		if(!bIsGameActive)
		{
			StartHardness = HardnessOverlap;
			StartRadius = RadiusOverlap;
		}

		float NewHardness = StartHardness + (HardnessActive * Value);
		float NewRadius = StartRadius + (RadiusActive * Value);

		MaterialInstance.SetScalarParameterValue(n"Hardness" , NewHardness);
		MaterialInstance.SetScalarParameterValue(n"Radius", NewRadius);
	}
}