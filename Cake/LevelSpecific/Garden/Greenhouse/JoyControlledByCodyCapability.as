import Peanuts.ButtonMash.Progress.ButtonMashProgress;
import Cake.LevelSpecific.Garden.Greenhouse.Joy;
import Cake.LevelSpecific.Garden.Greenhouse.JoyWidget;
import Cake.LevelSpecific.Garden.Greenhouse.JoyButtonMashBlob;

class JoyControlledByCodyCapability : UHazeCapability
{
	default CapabilityTags.Add(n"JoyButtonMashCapability");
	default CapabilityDebugCategory = n"Joy";
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 100;

	UPROPERTY()
	EInputDirections InputDirection = EInputDirections::Left;

	AHazePlayerCharacter MyPlayer;
	UButtonMashDefaultHandle ButtonMashHandleBlobDefault;
	AJoy Joy;

	bool bButtonMashingBlob = false;
	float ButtonMashMeshRate = 0;

	float StickInputFloat = 0;
	float BurstCameraShakeFloat = 0;
	bool bIsPlayingCameraShake = false;
	bool bIsShowingWidget = false;

	FVector2D PlayerLeftStickInput;
	FVector2D PlayerRightStickInput;
	bool bExtraLerpArm = false;

	bool bVOHalfWayDonePhaseOnePlayed = false;
	bool bVOHalfWayDonePhaseTwoPlayed = false;
	bool bVOHalfWayDonePhaseThreePlayed = false;

	float ReplayVOLineTimerMayHitBlobPhaseOne = 0;
	float ReplayVOLineTimerMayHitBlobPhaseTwo = 0;
	float ReplayVOLineTimerMayHitBlobPhaseThree = 0;

	float ExtraButtonMashRateMultiplier = 1;
	

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		MyPlayer = Cast<AHazePlayerCharacter>(Owner);
	}

	//Made local activate/dectivate to fix widget not dissepearing when it should
	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		AJoy JoyLocal= Cast<AJoy>(GetAttributeObject(n"Joy"));
		if(JoyLocal == nullptr)
			return EHazeNetworkActivation::DontActivate;
		if(JoyLocal.ButtonMashShouldDeactivate == true)
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateLocal;
	}


	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Joy.ButtonMashShouldDeactivate == true)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(Joy == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	
	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Joy = Cast<AJoy>(GetAttributeObject(n"Joy"));
		ButtonMashMeshRate = 0;
		StickInputFloat = 0;
		BurstCameraShakeFloat = 0;
		bIsPlayingCameraShake = false;
		bIsShowingWidget = false;
		bButtonMashingBlob = true;
		Joy.bAllowButtonMashExit = true;
		
		if(Joy.Phase == 1)
		{	
			StartFirstButtonMash();
		}
		if(Joy.Phase == 2)
		{
			StartSecondButtonMash();
		}
		if(Joy.Phase == 3)
		{
			StartFourthButtonMash();
		}
	}


	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Joy.StopCameraShakeCodyControllJoy();
		bButtonMashingBlob = false;
	//	MyPlayer.SetCapabilityAttributeObject(n"Joy", nullptr);
		Joy.bAllowButtonMashExit = false;
	//	Owner.UnblockCapabilities(CapabilityTags::Movement, this);
	//	MyPlayer.UnblockMovementSyncronization();

		Joy.IntButtonMash = 0;
		Joy.fInterpFloat = 0;
		Joy.fInterpFloatBlob = 0;
		Joy.ButtonMashProgress = 0;
		Joy.ButtonMashProgressBlob = 0;
		Joy.ButtonMashFloatSync.Value = 0;
		Joy.ButtonMashBlobloatSync.Value = 0;
		Joy.LeftPlayerInputVectorSync.Value = FVector(0,0,0);
		Joy.RightPlayerInputVectorSync.Value = FVector(0,0,0);

		if(ButtonMashHandleBlobDefault != nullptr)
			StopButtonMash(ButtonMashHandleBlobDefault);
	}
	

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(bButtonMashingBlob)
		{
			//Joy.ButtonMashProgress = StickInputFloat;
			//PrintToScreen("StickInputFloat " + StickInputFloat);
			CheckPlayerInputButtonMash(DeltaTime);
			PlayConstantCameraShake(DeltaTime);
			CameraBurstFunction(DeltaTime);

			if(Joy.IntButtonMash != 2)
			{
				
			}
		}
	}


	UFUNCTION()
	void CheckPlayerInputButtonMash(float DeltaTime)
	{
		//PrintToScreen("ButtonMashMeshRate " + ButtonMashMeshRate);
		float MashRate = ButtonMashHandleBlobDefault.MashRateControlSide;
		if(ButtonMashMeshRate < 1)
		{
			if(Joy.IntButtonMash != 2)
			{
				ButtonMashMeshRate += (MashRate /37) * DeltaTime;
			}
			else
			{
				ButtonMashMeshRate += (MashRate /37) * DeltaTime * ExtraButtonMashRateMultiplier;
			}
		}
		if(ButtonMashMeshRate > 0)
		{
			ButtonMashMeshRate -= 0.075 * DeltaTime;
		}

		if(Joy.IntButtonMash != 3)
		{
			Game::GetCody().SetFrameForceFeedback(((ButtonMashMeshRate/50) + 0.01f), ((ButtonMashMeshRate/50) + 0.01f));
		}
		else
		{
			Game::GetCody().SetFrameForceFeedback(0.035f, 0.035f);
		}
	
		if(Game::GetCody().HasControl())
		{
			if(Joy.IntButtonMash == 1)
			{
				Joy.ButtonMashProgress = ButtonMashMeshRate;
				Joy.ButtonMashProgressBlob = ButtonMashMeshRate * 1.45f;
				Joy.ButtonMashFloatSync.Value = ButtonMashMeshRate;
				Joy.ButtonMashBlobloatSync.Value = ButtonMashMeshRate * 1.45f;

				if(ButtonMashMeshRate >= 0.425f)
				{
					if(bVOHalfWayDonePhaseOnePlayed == false)
					{
						bVOHalfWayDonePhaseOnePlayed = true;
						Joy.VOCodyHalfWayButtonMashPhaseOne();
					}
				}
				if(ButtonMashMeshRate >= 0.8f)
				{
					ReplayVOLineTimerMayHitBlobPhaseOne -= DeltaTime;
					if(ReplayVOLineTimerMayHitBlobPhaseOne <= 0)
					{
						ReplayVOLineTimerMayHitBlobPhaseOne = 15;
						Joy.VOCodyTellsMayToAttackBlobPhaseOne();
					}
				}
			}
			if(Joy.IntButtonMash == 2)
			{
				if(bExtraLerpArm == false)
				{
					Joy.ButtonMashProgress = ButtonMashMeshRate;
					Joy.ButtonMashFloatSync.Value = ButtonMashMeshRate;
				}

				if(ButtonMashMeshRate >= 0.5f)
				{
					ExtraButtonMashRateMultiplier = 2.5f;
				}

				if(ButtonMashMeshRate >= 0.5f)
				{
					if(bVOHalfWayDonePhaseTwoPlayed == false)
					{
						bVOHalfWayDonePhaseTwoPlayed = true;
						Joy.VOCodyHalfWayButtonMashPhaseTwo();
					}
				}

				if(ButtonMashMeshRate >= 0.8f)
				{
					ReplayVOLineTimerMayHitBlobPhaseTwo -= DeltaTime;
					if(ReplayVOLineTimerMayHitBlobPhaseTwo <= 0)
					{
						ReplayVOLineTimerMayHitBlobPhaseTwo = 15;
						Joy.VOCodyTellsMayToAttackBlobPhaseTwo();
					}
				}

				if(ButtonMashMeshRate >= 0.8)
				{
					if(Game::GetCody().HasControl())
					{
						ExtraButtonMashRateMultiplier = 1;
						ArmDraggedDown();
					}
				}
			}
			if(bExtraLerpArm)
			{
				if(FMath::IsNearlyEqual(Joy.ButtonMashProgress, 1, 0.01f)  && FMath::IsNearlyEqual(Joy.ButtonMashFloatSync.Value, 1, 0.01f))
				{
					bExtraLerpArm = false;
				}
				else
				{
					Joy.ButtonMashProgress = FMath::Lerp(Joy.ButtonMashProgress, 1.f, DeltaTime * 1.65f);
					Joy.ButtonMashFloatSync.Value = FMath::Lerp(Joy.ButtonMashFloatSync.Value, 1.f, DeltaTime * 1.65f);
				}
			}

			if(Joy.IntButtonMash == 3)
			{
				if(bExtraLerpArm == false)
				{
					Joy.ButtonMashProgress = 1.0f;
					Joy.ButtonMashFloatSync.Value = 1.0f;
				}

				if(ButtonMashMeshRate >= 0.1f)
				{
					ReplayVOLineTimerMayHitBlobPhaseTwo -= DeltaTime;
					if(ReplayVOLineTimerMayHitBlobPhaseTwo <= 0)
					{
						ReplayVOLineTimerMayHitBlobPhaseTwo = 15;
						Joy.VOCodyTellsMayToAttackBlobPhaseTwo();
					}
				}

				Joy.ButtonMashProgressBlob = ButtonMashMeshRate * 1.5f;
				Joy.ButtonMashBlobloatSync.Value = ButtonMashMeshRate * 1.5f;
			}
			if(Joy.IntButtonMash == 4)
			{
				Joy.ButtonMashProgress = ButtonMashMeshRate;
				Joy.ButtonMashFloatSync.Value = ButtonMashMeshRate;

				
				if(ButtonMashMeshRate >= 0.5f)
				{
					if(bVOHalfWayDonePhaseThreePlayed == false)
					{
						bVOHalfWayDonePhaseThreePlayed = true;
						Joy.VOCodyHalfWayButtonMashPhaseThree();
					}
				}

				if(ButtonMashMeshRate >= 0.85f)
				{
					ReplayVOLineTimerMayHitBlobPhaseThree -= DeltaTime;
					if(ReplayVOLineTimerMayHitBlobPhaseThree <= 0)
					{
						ReplayVOLineTimerMayHitBlobPhaseThree = 15;
						Joy.VOCodyTellsMayToAttackBlobPhaseThree();
					}
				}

				if(ButtonMashMeshRate < 0.65f)
				{
					Joy.ButtonMashProgressBlob = ButtonMashMeshRate * 0.65;
					Joy.ButtonMashBlobloatSync.Value = ButtonMashMeshRate * 0.65;
				}
				else
				{
					Joy.ButtonMashProgressBlob = ButtonMashMeshRate * 1.2f;
					Joy.ButtonMashBlobloatSync.Value = ButtonMashMeshRate * 1.2;
				}
			}
		}
	}
	UFUNCTION(NetFunction)
	void ArmDraggedDown()
	{
		bExtraLerpArm = true;
		ButtonMashHandleBlobDefault.StopButtonMash();
		ButtonMashMeshRate = 0;
		StartThridButtonMash();
	}

	UFUNCTION()
	void PlayConstantCameraShake(float DeltaTime)
	{
		if(!bIsPlayingCameraShake)
		{
			Joy.PlayCameraShakeCodyControllJoy();
			bIsPlayingCameraShake = true;
		}
	}
	UFUNCTION()
	void CameraBurstFunction(float DeltaTime)
	{
		BurstCameraShakeFloat += DeltaTime * 0.75;
		if(BurstCameraShakeFloat > 1)
		{
			Joy.PlayCameraShakeCodyControllJoyBurst();
			BurstCameraShakeFloat = 0;
		}
	}

	UFUNCTION()
	void StartFirstButtonMash()
	{
		Joy.IntButtonMash = 1;
		ButtonMashHandleBlobDefault = StartButtonMashDefaultAttachToComponent(MyPlayer, Joy.Mesh, Joy.Mesh.GetSocketBoneName(n"RightHand"), FVector(0, 0,200));
		ButtonMashHandleBlobDefault.bIsExclusive = false;
	}
	
	UFUNCTION()
	void StartSecondButtonMash()
	{
		Joy.IntButtonMash = 2;
		ButtonMashHandleBlobDefault = StartButtonMashDefaultAttachToComponent(MyPlayer, Joy.Mesh, Joy.Mesh.GetSocketBoneName(n"LeftHand"), FVector::ZeroVector);
		ButtonMashHandleBlobDefault.bIsExclusive = false;
	}

	UFUNCTION()
	void StartThridButtonMash()
	{
		Joy.IntButtonMash = 3;
		ButtonMashHandleBlobDefault = StartButtonMashDefaultAttachToComponent(MyPlayer, Joy.BlobBack.RootComponent, NAME_None, FVector(200, 190, 190));
		ButtonMashHandleBlobDefault.bIsExclusive = true;
	}
	UFUNCTION()
	void StartFourthButtonMash()
	{
		Joy.IntButtonMash = 4;
		ButtonMashHandleBlobDefault = StartButtonMashDefaultAttachToComponent(MyPlayer, Joy.BlobHead.RootComponent, NAME_None, FVector(0, 0, 200));
		ButtonMashHandleBlobDefault.bIsExclusive = false;
	}
}

enum EInputDirections
{
	Left,
	Right,
	LeftRight
}