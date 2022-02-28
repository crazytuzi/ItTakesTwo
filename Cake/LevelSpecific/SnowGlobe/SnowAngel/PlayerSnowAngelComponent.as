import Peanuts.Animation.Features.SnowGlobe.LocomotionFeatureSnowAngel;
import Vino.Tutorial.TutorialPrompt;
import Vino.Tutorial.TutorialStatics;
import Peanuts.Foghorn.FoghornDirectorDataAssetBase;
import Peanuts.Foghorn.FoghornStatics;


class UPlayerSnowAngelComponent : UActorComponent
{
	UPROPERTY()
	bool bIsActive;

	UPROPERTY(Category = "Setup")
	UFoghornVOBankDataAssetBase VOLevelBank;

	/*** MATERIAL ***/
	UPROPERTY()
	TPerPlayer<TSubclassOf<ADecalActor>> DecalActorType;

	UPROPERTY(NotVisible)
	UMaterialInstanceDynamic MaterialInstance;

	/*** UI PROMPT ***/
	UPROPERTY()
    FTutorialPrompt StartSnowAngelPrompt;
    default ShowCancelText.Action = ActionNames::InteractionTrigger;
    default ShowCancelText.MaximumDuration = -1.f;

	UPROPERTY()
    FTutorialPrompt ShowCancelText;
    default ShowCancelText.Action = ActionNames::Cancel;
    default ShowCancelText.MaximumDuration = -1.f;

	UPROPERTY()
	FTutorialPrompt ShowAngelAction;
	default ShowAngelAction.Action = AttributeNames::MoveRight;
	default ShowAngelAction.MaximumDuration = -1.f;

	/*** CAMERA SETTINGS ***/
	UPROPERTY()
	FHazeCameraBlendSettings CameraBlendSettingsSettings;

	float SpringArmBlendTime = 1.5f;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CamSettings;

	float CameraViewBlendTime = 1.f;

	/*** ANIMATION ***/
	UPROPERTY()
	float RightAxisValue;

	UPROPERTY()
	float OtherRightAxisValue;

	UPROPERTY()
	bool bCanExit;

	UPROPERTY()
	bool bLanding;

	bool bHasActivated;

	UPROPERTY()
	ULocomotionFeatureSnowAngel SnowAngelFeatureCody;  

	UPROPERTY()
	ULocomotionFeatureSnowAngel SnowAngelFeatureMay;  

	/*** SHADERS ***/
	int SnowAngelCycleIteration = 1;
	bool bIsMovingUp;
	int MaxSnowAngleCycleIteration = 4;

	float InterpolateTime = 3.f;

	float Test = 0.f;

	float MaxHighValue;
	float MinLowValue;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		bIsMovingUp = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (MaterialInstance != nullptr)
		{		
			if (SnowAngelCycleIteration == 1)
			{
				//moving up
				MaterialInstance.SetScalarParameterValue(n"Layer1High", RightAxisValue);
				MaterialInstance.SetScalarParameterValue(n"Layer2Low", RightAxisValue);
				MaterialInstance.SetScalarParameterValue(n"Layer2High", RightAxisValue);
				MaterialInstance.SetScalarParameterValue(n"Layer3Low", RightAxisValue);
				MaterialInstance.SetScalarParameterValue(n"Layer3High", RightAxisValue);
				MaterialInstance.SetScalarParameterValue(n"Layer4Low", RightAxisValue);
				MaterialInstance.SetScalarParameterValue(n"Layer4High", RightAxisValue);
				MaxHighValue = RightAxisValue;
			}
			else if (SnowAngelCycleIteration == 2)
			{
				//moving down
				MaterialInstance.SetScalarParameterValue(n"Layer2Low", RightAxisValue);
				MaterialInstance.SetScalarParameterValue(n"Layer3Low", RightAxisValue);
				MaterialInstance.SetScalarParameterValue(n"Layer3High", RightAxisValue);
				MaterialInstance.SetScalarParameterValue(n"Layer4Low", RightAxisValue);
				MaterialInstance.SetScalarParameterValue(n"Layer4High", RightAxisValue);
				MinLowValue = RightAxisValue;
			}
			else if (SnowAngelCycleIteration == 3)
			{
				//moving up
				MaterialInstance.SetScalarParameterValue(n"Layer3High", RightAxisValue);
				MaterialInstance.SetScalarParameterValue(n"Layer4Low", RightAxisValue);
				MaterialInstance.SetScalarParameterValue(n"Layer4High", RightAxisValue);

				if (RightAxisValue > MaxHighValue)
				{
					MaterialInstance.SetScalarParameterValue(n"Layer2High", RightAxisValue);
					MaterialInstance.SetScalarParameterValue(n"Layer1High", RightAxisValue);
					MaxHighValue = RightAxisValue;
				}
			}
			else if (SnowAngelCycleIteration == 4)
			{
				//moving down
				MaterialInstance.SetScalarParameterValue(n"Layer4Low", RightAxisValue);

				if (RightAxisValue < MinLowValue)
				{
					MaterialInstance.SetScalarParameterValue(n"Layer3Low", RightAxisValue);
					MaterialInstance.SetScalarParameterValue(n"Layer2Low", RightAxisValue);	
					MinLowValue = RightAxisValue;				
				}				
			}
			else if (SnowAngelCycleIteration > 4)
			{
				if (MinLowValue > 0)
				{
					if (RightAxisValue < MinLowValue)
					{
						MinLowValue = RightAxisValue;
						MaterialInstance.SetScalarParameterValue(n"Layer2Low", RightAxisValue);	
						MaterialInstance.SetScalarParameterValue(n"Layer3Low", RightAxisValue);
						MaterialInstance.SetScalarParameterValue(n"Layer4Low", RightAxisValue);
					}	
				}
				else
				{
					if (MaterialInstance.GetScalarParameterValue(n"Layer1Low") > RightAxisValue)
						MaterialInstance.SetScalarParameterValue(n"Layer1Low", RightAxisValue);

					if (MaterialInstance.GetScalarParameterValue(n"Layer2Low") > RightAxisValue)
						MaterialInstance.SetScalarParameterValue(n"Layer2Low", RightAxisValue);

					if (MaterialInstance.GetScalarParameterValue(n"Layer3Low") > RightAxisValue)
						MaterialInstance.SetScalarParameterValue(n"Layer3Low", RightAxisValue);

					if (MaterialInstance.GetScalarParameterValue(n"Layer4Low") > RightAxisValue)
						MaterialInstance.SetScalarParameterValue(n"Layer4Low", RightAxisValue);
				}
	
				if (MaxHighValue < 1)
				{
					if (RightAxisValue > MaxHighValue)
					{
						MaxHighValue = RightAxisValue;
						MaterialInstance.SetScalarParameterValue(n"Layer1High", RightAxisValue);
						MaterialInstance.SetScalarParameterValue(n"Layer2High", RightAxisValue);
						MaterialInstance.SetScalarParameterValue(n"Layer3High", RightAxisValue);
						MaterialInstance.SetScalarParameterValue(n"Layer4High", RightAxisValue);
					}
				}
				else
				{
					if (MaterialInstance.GetScalarParameterValue(n"Layer1High") < RightAxisValue)
						MaterialInstance.SetScalarParameterValue(n"Layer1High", RightAxisValue);

					if (MaterialInstance.GetScalarParameterValue(n"Layer2High") < RightAxisValue)
						MaterialInstance.SetScalarParameterValue(n"Layer2High", RightAxisValue);

					if (MaterialInstance.GetScalarParameterValue(n"Layer3High") < RightAxisValue)
						MaterialInstance.SetScalarParameterValue(n"Layer3High", RightAxisValue);

					if (MaterialInstance.GetScalarParameterValue(n"Layer4High") < RightAxisValue)
						MaterialInstance.SetScalarParameterValue(n"Layer4High", RightAxisValue);
				}
			}
		}
	}

	void ShowActivateAngelPrompt(AHazePlayerCharacter Player)
	{
		ShowTutorialPrompt(Player, StartSnowAngelPrompt, this); 
	}

	void ShowAngelActionPrompt(AHazePlayerCharacter Player)
	{
		ShowTutorialPrompt(Player, ShowAngelAction, this);
	}

	void ShowCancelAngelPrompt(AHazePlayerCharacter Player)
	{
		ShowCancelPrompt(Player, this); 
	}

	void HideAngelPrompt(AHazePlayerCharacter Player)
	{
		RemoveTutorialPromptByInstigator(Player, this); 
	}

	void HideCancelPrompt(AHazePlayerCharacter Player)
	{
		RemoveCancelPromptByInstigator(Player, this);
	}

	void ResetCycleIterationValue()
	{		
		SnowAngelCycleIteration = 1;
		MaxHighValue = 0.f;
		MinLowValue = 0.f;
		MaterialInstance = nullptr;
	}

	void PlaySnowAngelVO(AHazePlayerCharacter Player)
	{
		if (Player.IsMay())
			PlayFoghornVOBankEvent(VOLevelBank, n"FoghornDBSnowGlobeTownSnowAngelsInteractMay");
		else
			PlayFoghornVOBankEvent(VOLevelBank, n"FoghornDBSnowGlobeTownSnowAngelsInteractCody");
	}
}

//Living up to his name
namespace Tom
{
	float Clamp(float Value, float Min, float Max)
	{
		float InValue = Value;

		if (InValue < Min)
			InValue = Min;
		else if (InValue > Max)
			InValue = Max;

		return InValue;
	}
}