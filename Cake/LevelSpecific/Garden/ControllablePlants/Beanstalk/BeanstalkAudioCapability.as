import Peanuts.Audio.AudioStatics;
import Peanuts.Foghorn.FoghornStatics;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.Beanstalk.Beanstalk;
import Cake.LevelSpecific.Garden.ControllablePlants.Beanstalk.BeanstalkTags;
import Vino.Audio.Capabilities.AudioTags;

class UBeanstalkAudioCapability : UHazeCapability
{
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OnBeanstalkOnEnterEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BeanstalkSubmergeEvent;
	
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OnBeanstalkOnExitSoilEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BeanstalkLeafsOutEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BeanstalkLeafsInEvent;

	AHazePlayerCharacter PlayerController;
	ABeanstalk BeanstalkOwner;
	UHazeMovementComponent MoveComp;
	UHazeAkComponent BeanstalkHazeAkComp;

	float LastAngularVelocityValue = 0.f;
	float LastDirectionRtpcValue = 0.f;
	float LastLengthRtpcValue = 0.f;
	float LastIsMovingRtpcValue = 0.f;
	float LastSlopeTiltValue = 0.f;

	private bool bHasPlayedExit = false;
	private bool bFlowerIsSubmerging = true;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerController = Game::GetCody();
		BeanstalkOwner = Cast<ABeanstalk>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		BeanstalkHazeAkComp = UHazeAkComponent::GetOrCreate(Owner);
		HazeAudio::SetPlayerPanning(BeanstalkHazeAkComp, PlayerController);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!BeanstalkOwner.bBeanstalkActive)
			return EHazeNetworkActivation::DontActivate;

		if(BeanstalkOwner.BeanstalkSoil == nullptr)
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(BeanstalkOwner == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(bHasPlayedExit)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PlayerController.BlockCapabilities(AudioTags::PlayerAudioVelocityData, this);
		PlayerController.BlockCapabilities(AudioTags::AudioListener, this);
		SetCanPlayEfforts(PlayerController.PlayerHazeAkComp, false);
		PlayerController.PlayerListener.AttachTo(BeanstalkOwner.BeanstalkHead, AttachType = EAttachLocation::SnapToTarget);	
		bHasPlayedExit = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{			
		SetMovementRtpcValues();

		if(ConsumeAction(n"AudioBeanStalkEmerge") == EActionStateStatus::Active)
		{
			BeanstalkHazeAkComp.HazePostEvent(OnBeanstalkOnEnterEvent);
			//PrintToScreenScaled("BeanStalk On Enter - Emerge", 2.f, FLinearColor :: LucBlue, 2.f);
		}
		
		if(ConsumeAction(n"AudioSpawnLeaf") == EActionStateStatus::Active)
			OnAddLeaf();					

		FVector LeafLoc;
		if(ConsumeAttribute(n"AudioOnLeafRemoved", LeafLoc))
			OnRemoveLeaf(LeafLoc);

		if(ConsumeAction(n"Audio_OnExitSoil") == EActionStateStatus::Active)
		{
			BeanstalkHazeAkComp.HazePostEvent(OnBeanstalkOnExitSoilEvent);
			//PrintToScreenScaled("BeanStalk On Exit Soil", 2.f, FLinearColor :: LucBlue, 2.f);
			bHasPlayedExit = true;
		}

	}	

	void SetMovementRtpcValues()
	{
		// Is Moving
		if(ConsumeAction(n"IsMoving_Audio") == EActionStateStatus::Active)
		{
			BeanstalkHazeAkComp.SetRTPCValue(HazeAudio::RTPC::BeanstalkIsMoving, 1.f, 700.f);
		}
						
		if(ConsumeAction(n"IsNotMoving_Audio") == EActionStateStatus::Active)
		{
			BeanstalkHazeAkComp.SetRTPCValue(HazeAudio::RTPC::BeanstalkIsMoving, 0.f, 700.f);
		}
			
					

		// Angular Velocity
		float AngularVelocityRtpcValue = FMath::Abs(BeanstalkOwner.CurrentVelocity) / 1000.f;
		if(LastAngularVelocityValue != AngularVelocityRtpcValue)
		{
			BeanstalkHazeAkComp.SetRTPCValue(HazeAudio::RTPC::BeanstalkAngularVelocity, AngularVelocityRtpcValue);
			//PrintToScreenScaled(("AngularVelocityRtpcValue " + AngularVelocityRtpcValue), 0.f, FLinearColor :: LucBlue, Scale = 3.f);
			LastAngularVelocityValue = AngularVelocityRtpcValue;
		}

		// Direction Forwards / Backwards
		if(LastDirectionRtpcValue != BeanstalkOwner.CurrentMovementDirection)
		{
			BeanstalkHazeAkComp.SetRTPCValue(HazeAudio::RTPC::BeanstalkMovementDirection, BeanstalkOwner.CurrentMovementDirection, 700.f);
			//PrintToScreenScaled(("Movement Direction " + BeanstalkOwner.CurrentMovementDirection), 2.f, FLinearColor :: LucBlue, Scale = 3.f);
			LastDirectionRtpcValue = BeanstalkOwner.CurrentMovementDirection;
		}		

		// Spline Length
		float LengthRtpcValue = BeanstalkOwner.SplineLength / BeanstalkOwner.BeanstalkMaxLength;
		if(LengthRtpcValue != LastLengthRtpcValue)
		{
			BeanstalkHazeAkComp.SetRTPCValue(HazeAudio::RTPC::BeanstalkCurrentLength, LengthRtpcValue);	
			//PrintToScreenScaled(("LengthRtpcValue " + LengthRtpcValue), 0.f, FLinearColor :: LucBlue, Scale = 3.f);		
			LastLengthRtpcValue = LengthRtpcValue;

			if (!bFlowerIsSubmerging && LengthRtpcValue < 0.1f)
			{
				bFlowerIsSubmerging = true;
				BeanstalkHazeAkComp.HazePostEvent(BeanstalkSubmergeEvent);
				//PrintToScreenScaled("Beastalk Submerged", 2.f, FLinearColor :: LucBlue, 2.f);
			}
			else if (LengthRtpcValue >= 0.1)
				bFlowerIsSubmerging = false;
		}	

		// Beanstalk Head Tilt
		float BeanstalkHeadTilt = GetBeanstalkHeadTiltValue();
		
		// Head Tilt Delta
		float HeadTiltDelta = 0.f;

		if(ConsumeAttribute(n"AudioHeadRotationDelta", HeadTiltDelta))
		{
			BeanstalkHazeAkComp.SetRTPCValue(HazeAudio::RTPC::BeanstalkHeadTiltDelta, HeadTiltDelta);	
		}
		else
		{
			BeanstalkHazeAkComp.SetRTPCValue(HazeAudio::RTPC::BeanstalkHeadTiltDelta, 0.f);
		}
	}

	float GetBeanstalkHeadTiltValue()
	{
		FVector VelocityPlaneForward = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
		float HeadTilt = Math::DotToDegrees(MoveComp.Velocity.GetSafeNormal().DotProduct(VelocityPlaneForward));
		HeadTilt = HeadTilt * FMath::Sign(MoveComp.Velocity.DotProduct(MoveComp.WorldUp));
		float NormalizedHeadTilt = HazeAudio::NormalizeRTPC(HeadTilt, -70.f, 70.f, -1.f, 1.f);
		//PrintToScreenScaled(("HeadTilt " + NormalizedHeadTilt), 0.f, FLinearColor :: LucBlue, Scale = 3.f);	

		return NormalizedHeadTilt;
	}

	UFUNCTION()
	void OnAddLeaf()
	{
		if(BeanstalkLeafsOutEvent != nullptr)
		{
			float LeafCount = BeanstalkOwner.LeafPairCollection.Num();

			BeanstalkHazeAkComp.SetRTPCValue(HazeAudio::RTPC::BeanstalkLeafCount, LeafCount);			
			BeanstalkHazeAkComp.HazePostEvent(BeanstalkLeafsOutEvent);
		}
	}

	UFUNCTION()
	void OnRemoveLeaf(FVector LeafLocation)
	{
		if(BeanstalkLeafsInEvent != nullptr)
		{		
			UHazeAkComponent::HazePostEventFireForget(BeanstalkLeafsInEvent, FTransform(LeafLocation));		
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PlayerController.PlayerListener.DetachFromComponent();
		PlayerController.UnblockCapabilities(AudioTags::AudioListener, this);
		PlayerController.UnblockCapabilities(AudioTags::PlayerAudioVelocityData, this);
		SetCanPlayEfforts(PlayerController.PlayerHazeAkComp, true);	
	}
	
}