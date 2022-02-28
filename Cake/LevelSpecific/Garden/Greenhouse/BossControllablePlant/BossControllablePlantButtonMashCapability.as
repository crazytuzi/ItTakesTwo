import Cake.LevelSpecific.Garden.Greenhouse.BossControllablePlant.BossControllablePlant;

import Peanuts.ButtonMash.ButtonMashStatics;
import Peanuts.ButtonMash.Progress.ButtonMashProgress;
import Peanuts.ButtonMash.Silent.ButtonMashSilent;

class UBossControllablePlantButtonMashCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 10;

	ABossControllablePlant Plant;

    UButtonMashProgressHandle ButtonMashHandle;

	UControlPlantWidget PlantProgressWidget = nullptr;	
	UHazeInputButton ProgressInputWidget = nullptr;

	bool bWidgetsAreHidden = false;

	float ButtonMashSpeed;
	float ButtonMashConstantDecreaseSpeed;
	float ButtonMashFreeDecreaseSpeed;
	float ButtonMashCooldown;

	float CooldownTimer = 0.0f;
	bool bFreeDecreaseTimeSet = false;
	float FreeDecreaseSpeed = 0.0f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Plant = Cast<ABossControllablePlant>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!Plant.bIsAlive)
		{
			return EHazeNetworkActivation::DontActivate; 
		}

		if (!Plant.bBeingControlled)
		{
			return EHazeNetworkActivation::DontActivate; 
		}
        	
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{	
		if(!Plant.bIsAlive)
		{
			return EHazeNetworkDeactivation::DeactivateLocal;
		}

		if (!Plant.bBeingControlled)
		{
			return EHazeNetworkDeactivation::DeactivateLocal; 
		}
        	
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ButtonMashSpeed = Plant.ButtonMashAddSpeed;
		ButtonMashConstantDecreaseSpeed = Plant.ButtonMashConstantDecreaseSpeed;
		ButtonMashFreeDecreaseSpeed = Plant.ButtonMashFreeDecreaseSpeed;
		ButtonMashCooldown = Plant.ButtonMashCooldown;

		if(Plant.UseButtonMash)
		{
       		ButtonMashHandle = StartButtonMashProgressAttachToComponent(Plant.ControllingPlayer, Plant.ButtonMashAttachPoint, n"", FVector::ZeroVector);
			return;
		}
		
		AddProgressWidgets();						
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(Plant.UseButtonMash)
		{
			ButtonMashHandle.Progress = 0.0f;
			ButtonMashHandle.StopButtonMash();
			ButtonMashHandle = nullptr;
		}
		else
		{
			RemoveProgressWidgets();
		}

		Plant.CurrentMashProgress = 0.0f;

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!HasControl())
		{
			return;
		}

		if(Plant.UseButtonMash)
		{
			float DecreasementSpeed = 0.0f;
			float DeltaMashSpeed = 0.0f;

			DeltaMashSpeed = ButtonMashHandle.MashRateControlSide * ButtonMashSpeed * DeltaTime;

			if(ButtonMashHandle.MashRateControlSide <= 2.0f)
			{
				CooldownTimer += DeltaTime;
				if(CooldownTimer >= ButtonMashCooldown)
				{
					if(!bFreeDecreaseTimeSet)
					{
						bFreeDecreaseTimeSet = true;
						FreeDecreaseSpeed = Plant.CurrentMashProgress/Plant.ButtonMashFreeDecreaseTime;
					}

					DecreasementSpeed = FreeDecreaseSpeed;

				}
				else if(CooldownTimer < ButtonMashCooldown)
					DecreasementSpeed = ButtonMashConstantDecreaseSpeed;			
				
			}
			else
			{
				CooldownTimer = 0.0f;
				bFreeDecreaseTimeSet = false;
				DecreasementSpeed = ButtonMashConstantDecreaseSpeed;
			}

			Plant.AddProgress(DeltaMashSpeed, DecreasementSpeed * DeltaTime);
			
			ButtonMashHandle.Progress = Plant.CurrentMashProgress;
		}

		else
		{
			float DecreasementSpeed = 0.0f;
			float DeltaMashSpeed = 0.0f;

			bool InputIsHeld = false;
			if(Plant.IsRightPlant)
			{
				if(Plant.BossPlantsComp.RightTrigger)
					InputIsHeld = true;
			}
			else
			{
				if(Plant.BossPlantsComp.LeftTrigger)
					InputIsHeld = true;
			}

			if(InputIsHeld)
			{
				DecreasementSpeed = ButtonMashConstantDecreaseSpeed;
				DeltaMashSpeed = ButtonMashSpeed * 2.0f * DeltaTime;
			}
			else
			{
				DecreasementSpeed = ButtonMashFreeDecreaseSpeed;			

			}

			Plant.AddProgress(DeltaMashSpeed, DecreasementSpeed * DeltaTime);
			
			//ButtonMashHandle.Progress = Plant.CurrentMashProgress;
			PlantProgressWidget.SetProgress(Plant.CurrentMashProgress);


			if(Plant.bFullyButtonMashed && !bWidgetsAreHidden)
			{
				RemoveProgressWidgets();
				bWidgetsAreHidden = true;
			}
			else if(!Plant.bFullyButtonMashed && bWidgetsAreHidden)
			{
				AddProgressWidgets();
				bWidgetsAreHidden = false;
			}


			if(!Plant.bBeingControlled)
				return;

			FVector2D Input;
			if(Plant.IsRightPlant)
				Input = Plant.BossPlantsComp.RightStickInput;
			else
				Input = Plant.BossPlantsComp.LeftStickInput;

			Plant.StickInput = Input;

		}
	}


	UFUNCTION()
	void AddProgressWidgets()
	{
		PlantProgressWidget = Cast<UControlPlantWidget>(Plant.ControllingPlayer.AddWidget(Plant.ProgressWidgetClass));

		PlantProgressWidget.AttachWidgetToComponent(Plant.ButtonMashAttachPoint);
		PlantProgressWidget.SetWidgetShowInFullscreen(true);

		ProgressInputWidget = Cast<UHazeInputButton>((Plant.ControllingPlayer.AddWidget(Plant.ProgressInputWidgetClass)));

		if(Plant.IsRightPlant)
			ProgressInputWidget.ActionName = ActionNames::WeaponFire;
		else
			ProgressInputWidget.ActionName = ActionNames::WeaponAim;

		ProgressInputWidget.AttachWidgetToComponent(Plant.ButtonMashAttachPoint);
		
		ProgressInputWidget.SetWidgetShowInFullscreen(true);
	}

	UFUNCTION()
	void RemoveProgressWidgets()
	{
		Plant.ControllingPlayer.RemoveWidget(ProgressInputWidget);
		PlantProgressWidget.Destroy();
	}
}
