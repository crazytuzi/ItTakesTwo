import Peanuts.Triggers.PlayerTrigger;
import Vino.Movement.Capabilities.GroundPound.CharacterGroundPoundFallCapabilty;

class AAccordion : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)	
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSkeletalMeshComponentBase MeshBody;
	default MeshBody.bUseDisabledTickOptimizations = true;
	default MeshBody.DisabledVisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::OnlyTickPoseWhenRendered;

	UPROPERTY()
	APlayerTrigger PlayerTrigger;
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Collision1;
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Collision2;
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Collision3;
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Collision1Lower;
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Collision2Lower;
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Collision3Lower;
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent CollisionFoundation1;
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent CollisionFoundation2;
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent CollisionFoundation3;

	FHazeAcceleratedFloat AcceleratedFloat;
	UPROPERTY()
	float MinClamp = 0;
	UPROPERTY()
	float MaxClamp = 1;
	UPROPERTY()
	float AccelerateTooForward = 1;
	UPROPERTY()
	float AccelerateDurationForward = 10;
	private float AccelerateDurationForwardSave;
	UPROPERTY()
	float AccelerateTooBackwards = 0;
	UPROPERTY()
	float AccelerateDurationBackwards = 10;
	int PlayerInt;
	bool bHasPlayedSoundIn = false;
	bool bbHasPlayedInSoundOut = false;
	private bool bPlayerHasSteppedOn = false;
	float AccordionProcent = 0;
	UPROPERTY()
	bool bPrintTexts = false;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent HazeDisable;
	default HazeDisable.bAutoDisable = true;
	default HazeDisable.bActorIsVisualOnly = true;
	default HazeDisable.AutoDisableRange = 5000.f;

	UPROPERTY(DefaultComponent, NotVisible)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent PushInEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent PushOutEvent;

	private FHazeAudioEventInstance PushInEventInstance;
	private FHazeAudioEventInstance PushOutEventInstance;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerTrigger.OnPlayerEnter.AddUFunction(this, n"OnComponentBeginOverlap");
		PlayerTrigger.OnPlayerLeave.AddUFunction(this, n"OnComponentEndOverlap");
		PlayerTrigger.AttachToComponent(MeshBody, MeshBody.GetSocketBoneName(n"Body5"), EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		PlayerTrigger.AddActorLocalOffset(FVector(0, 0, 200));
		Collision1.AttachToComponent(MeshBody, MeshBody.GetSocketBoneName(n"Body5"), EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		Collision1.AddLocalOffset(FVector(0, 0, 75));
		Collision2.AttachToComponent(MeshBody, MeshBody.GetSocketBoneName(n"Body5"), EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		Collision2.AddLocalOffset(FVector(0, 0, 75));
		Collision3.AttachToComponent(MeshBody, MeshBody.GetSocketBoneName(n"Body5"), EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		Collision3.AddLocalOffset(FVector(0, 0, 75));

		Collision1Lower.AttachToComponent(MeshBody, MeshBody.GetSocketBoneName(n"Body5"), EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		Collision1Lower.AddLocalOffset(FVector(0, 0, -150));
		Collision2Lower.AttachToComponent(MeshBody, MeshBody.GetSocketBoneName(n"Body5"), EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		Collision2Lower.AddLocalOffset(FVector(0, 0, -150));
		Collision3Lower.AttachToComponent(MeshBody, MeshBody.GetSocketBoneName(n"Body5"), EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		Collision3Lower.AddLocalOffset(FVector(0, 0, -150));

		AccelerateDurationForwardSave = AccelerateDurationForward;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		SetBlendSpaceValues(AccordionProcent, AccordionProcent);

		if(PlayerInt == 0)
		{
			if(AccordionProcent > 0)
			{
				AcceleratedFloat.AccelerateTo(AccelerateTooBackwards, AccelerateDurationBackwards, DeltaSeconds);
				//UHazeAkComponent::HazePostEventFireForget(PushOutEvent, GetActorTransform());
				bPlayerHasSteppedOn = false;		
				bHasPlayedSoundIn = false;		
			}		
		}
		if(PlayerInt == 1 or PlayerInt == 2)
		{
			bPlayerHasSteppedOn = true;
			if(AccordionProcent < 1)
			{
				AcceleratedFloat.AccelerateTo(AccelerateTooForward, AccelerateDurationForward, DeltaSeconds);
			}
		}

		AccordionProcent = FMath::Clamp(AccordionProcent, MinClamp, MaxClamp);
		AccordionProcent = AcceleratedFloat.Value;
		AccordionProcent = FMath::Clamp(AccordionProcent, MinClamp, MaxClamp);

		if(AccordionProcent > MinClamp && AccordionProcent < MaxClamp)
		{
			if(bPlayerHasSteppedOn && !bHasPlayedSoundIn)
			{
				bHasPlayedSoundIn = true;
				if(HazeAkComp.EventInstanceIsPlaying(PushOutEventInstance))
					HazeAkComp.HazeStopEvent(PushOutEventInstance.PlayingID, 250.f);

				PushInEventInstance = HazeAkComp.HazePostEvent(PushInEvent);
				bbHasPlayedInSoundOut = false;
			}
			
			if(!bPlayerHasSteppedOn && !bbHasPlayedInSoundOut)
			{
				bbHasPlayedInSoundOut = true;
				if(HazeAkComp.EventInstanceIsPlaying(PushInEventInstance))
					HazeAkComp.HazeStopEvent(PushInEventInstance.PlayingID, 250.f);

				PushOutEventInstance = HazeAkComp.HazePostEvent(PushOutEvent);
				bHasPlayedSoundIn = false;
			}
		}	

		if(!bPrintTexts)
			return;

		//Print("bPlayingSoundForward  " + bPlayingSoundForward);
		//Print("AccordionProcent  " + AccordionProcent);
		//Print("AcceleratedFloat.Value  " + AcceleratedFloat.Value);
		//Print("PlayerInt   "+ PlayerInt);
		//Print("SoundPlaying   "+ bSoundPlaying);
		//Print("AccelerateDurationForward  " + AccelerateDurationForward);
	}

	UFUNCTION(NetFunction)
	void NetAddPlayer(AHazePlayerCharacter Player)
	{
		PlayerInt ++;
	}
	UFUNCTION(NetFunction)
	void NetRemovePlayer(AHazePlayerCharacter Player)
	{
		PlayerInt --;
	}

	UFUNCTION()
	void OnComponentBeginOverlap(AHazePlayerCharacter Player)
	{
		if(Player.HasControl())
		{
			NetAddPlayer(Player);
			if(Player.IsAnyCapabilityActive(UCharacterGroundPoundFallCapability::StaticClass()))
			{
				AccelerateDurationForward = 1.f;
				System::SetTimer(this, n"RestoreDurationValue", 2.f, true);
			}
		}
		else
		{
			if(Player.IsAnyCapabilityActive(UCharacterGroundPoundFallCapability::StaticClass()))
			{
				AccelerateDurationForward = 1.f;
			}
		}
	}

	UFUNCTION()
	void OnComponentEndOverlap(AHazePlayerCharacter Player)
	{
		if(Player.HasControl())
		{
			NetRemovePlayer(Player);
		}
	}

	UFUNCTION()
	void RestoreDurationValue()
	{
		AccelerateDurationForward = AccelerateDurationForwardSave;
	}
}

