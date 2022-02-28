import Cake.LevelSpecific.Garden.Greenhouse.BossRoomRootBulb;
import Vino.Tutorial.TutorialStatics;

import Peanuts.ButtonMash.ButtonMashStatics;
import Peanuts.ButtonMash.Progress.ButtonMashProgress;
import Peanuts.ButtonMash.Silent.ButtonMashSilent;

class UBossRoomRootBulbBarrierCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 10;

	ABossRoomRootBulb Bulb;
	UBossControllablePlantPlayerComponent BossPlantsComp;

    UButtonMashProgressHandle ButtonMashHandle;

	bool bLeftClosing= true;
	float LeftLastInput = 0.0f;
	float LeftLastProgress = 0.0f;
	float LeftTargetProgress = 0.0f;

	bool bLeftBarrierUp = false;

	bool bRightClosing = true;
	float RightLastInput = 0.0f;
	float RightLastProgress = 0.0f;
	float RightTargetProgress = 0.0f;

	bool bRightBarrierUp = false;

	bool bBothBarriersAreUp = true;
	
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Bulb = Cast<ABossRoomRootBulb>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!Bulb.bCodyInSoil)
		{
			return EHazeNetworkActivation::DontActivate; 
		}
		
		if(Bulb.ConnectedSubmersibleSoil.CurrentSection != Bulb.SectionNumber)
		{
			return EHazeNetworkActivation::DontActivate; 
		}
        	
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{	
		if(!Bulb.bCodyInSoil)
		{
			return EHazeNetworkDeactivation::DeactivateLocal;
		}

		if(Bulb.ConnectedSubmersibleSoil.CurrentSection != Bulb.SectionNumber)
		{
			return EHazeNetworkDeactivation::DeactivateLocal;
		}
        	
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		BossPlantsComp = UBossControllablePlantPlayerComponent::Get(Game::GetCody());

		FTutorialPrompt LeftTutorialPrompt;
		LeftTutorialPrompt.Action = AttributeVectorNames::MovementRaw;
		LeftTutorialPrompt.DisplayType = ETutorialPromptDisplay::LeftStick_Left;
		ShowTutorialPrompt(Game::GetCody(), LeftTutorialPrompt, Bulb);

		FTutorialPrompt RightTutorialPrompt;
		RightTutorialPrompt.Action = AttributeVectorNames::RightStickRaw;
		RightTutorialPrompt.DisplayType = ETutorialPromptDisplay::RightStick_Right;
		ShowTutorialPrompt(Game::GetCody(), RightTutorialPrompt, Bulb);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RemoveTutorialPromptByInstigator(Game::GetCody(), Bulb);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float LeftXInput = BossPlantsComp.LeftStickInput.X;
		LeftXInput *= -1;
		
		float RightXInput = BossPlantsComp.RightStickInput.X;

		//Print("LeftXInput " + LeftXInput);
		// Print("RightXInput " + RightXInput);
		// Print("RightLastInput " + RightLastInput);
	
		
		Bulb.RightBarrierCurrentValue = CalculateBarrierProgress(true, RightXInput, DeltaTime);
		Bulb.LeftBarrierCurrentValue = CalculateBarrierProgress(false, LeftXInput, DeltaTime);

		if(bRightBarrierUp && Bulb.RightBarrierCurrentValue < 0.9f)
			bRightBarrierUp = false;
		else if(!bRightBarrierUp && Bulb.RightBarrierCurrentValue >= 0.9f)
			bRightBarrierUp = true;
		
		if(bLeftBarrierUp && Bulb.RightBarrierCurrentValue < 0.9f)
			bLeftBarrierUp = false;
		else if(!bLeftBarrierUp && Bulb.RightBarrierCurrentValue >= 0.9f)
			bLeftBarrierUp = true;

		if(bRightBarrierUp && bLeftBarrierUp)
		{
			if(!bBothBarriersAreUp)
			{
				Bulb.SickleCuttableComp.ChangeValidActivator(EHazeActivationPointActivatorType::May);
				bBothBarriersAreUp = true;
			}

		}
		else if(bBothBarriersAreUp)
		{
			Bulb.SickleCuttableComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);
			bBothBarriersAreUp = false;
		}

		float CurrentRightRollRotation = FMath::Lerp(0.0f, -50.0f, Bulb.RightBarrierCurrentValue);
		Bulb.RightBarrierRoot.SetRelativeRotation(FRotator(Bulb.RightBarrierRoot.RelativeRotation.Pitch, Bulb.RightBarrierRoot.RelativeRotation.Yaw, CurrentRightRollRotation));

		float CurrentLeftRollRotation = FMath::Lerp(0.0f, 50.0f, Bulb.LeftBarrierCurrentValue);
		Bulb.LeftBarrierRoot.SetRelativeRotation(FRotator(Bulb.LeftBarrierRoot.RelativeRotation.Pitch, Bulb.LeftBarrierRoot.RelativeRotation.Yaw, CurrentLeftRollRotation));
	}


	float CalculateBarrierProgress(bool IsRightBarrier, float XInput, float DeltaTime)
	{
		float CurrentProgress = IsRightBarrier ? Bulb.RightBarrierCurrentValue : Bulb.LeftBarrierCurrentValue;
		float LastProgress = IsRightBarrier ? RightLastProgress : LeftLastProgress;
		bool Closing = IsRightBarrier ? bRightClosing : bLeftClosing;
		float Input = XInput; 
		float LastInput = IsRightBarrier ? RightLastInput : LeftLastInput; 

		float TargetProgress = 0.0f; 
		//float CurrentSpeed;

		if(FMath::IsNearlyEqual(Input, LastInput, 0.05f))
		{
			Input = LastInput;
		}

		if(Input >= LastInput && Input > 0.0f)
		{
			if(Closing)
			{
				LastProgress = CurrentProgress;
				Closing = false;
			}
		}
		else
		{
			if(!Closing)
			{
				LastProgress = CurrentProgress;
				Closing = true;
			}
		}

		if(Input >= 0)
			TargetProgress = Input;


		if(IsRightBarrier)
		{
			// if(Closing && Closing != bRightClosing)
			// {
			// 	Print("Right " + Closing);
				
			// }
		 	RightLastInput = Input; 
			bRightClosing = Closing;
			RightLastProgress = LastProgress;
		}
		else
		{
			// if(Closing && Closing != bLeftClosing)
			// {
			// 	Print("LEft " + Closing);
				
			// }

			LeftLastInput = Input;
			bLeftClosing = Closing;
			LeftLastProgress = LastProgress;
		}

		if(Closing && CurrentProgress == 0.0f)
			return 0.0f;
		else if(!Closing && FMath::IsNearlyEqual(CurrentProgress, TargetProgress, 0.05f))
			return CurrentProgress;

		if(!Closing && CurrentProgress < TargetProgress)
		{
			float Percentage = (CurrentProgress - LastProgress) / (TargetProgress - LastProgress);
			float CurrentSpeed = Bulb.BarrierOpeningCurve.GetFloatValue(Percentage);
			CurrentProgress += Input * Bulb.OpeningBarrierSpeed * CurrentSpeed * DeltaTime;
			CurrentProgress = FMath::Clamp(CurrentProgress, 0.0f, 1.0f);
		}
		else
		{
			float Percentage = (CurrentProgress - LastProgress) / (TargetProgress - LastProgress);
			float CurrentSpeed = Bulb.BarrierClosingCurve.GetFloatValue(Percentage);

			float ClosingSpeed;
			
			if(Input > 0)
				ClosingSpeed = Bulb.SlowerClosingBarrierSpeed;
			else
				ClosingSpeed = Bulb.ClosingBarrierSpeed;

			float DeltaSpeed = ClosingSpeed * CurrentSpeed * DeltaTime;

			if(Input < 0)
			{
				float Multiplier = (Input * -1) * 2;
				DeltaSpeed * 2;
			}
			
			CurrentProgress -= DeltaSpeed;
			CurrentProgress = FMath::Clamp(CurrentProgress, 0.0f, 1.0f);
		}


		return CurrentProgress;
	}
}
