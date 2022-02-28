import Peanuts.Audio.AudioStatics;
import Peanuts.Audio.HazeAudioManager.HazeAudioManager;
import Peanuts.Audio.HazeAudioManager.AudioManagerStatics;

class UAudioTimeDialationCapability : UHazeCapability
{	
	default CapabilityTags.Add(n"AudioTimeDialation");
	default CapabilityDebugCategory = n"Audio";

	UHazeAudioManager AudioManager;

	bool bHasEnteredSlowMo = false;
	float LastTimeDilationAmountRtpcValue;
	float LastSlowMoActiveValue = -1;

	
	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const 
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{		
		AudioManager = GetAudioManager();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UWorld LocalWorld = GetWorld();

		if(LocalWorld != nullptr && LocalWorld.IsGameWorld())
		{
			AHazeWorldSettings HazeWorldSettings = Cast<AHazeWorldSettings>(LocalWorld.GetWorldSettings());
			if (HazeWorldSettings != nullptr)
			{
				float TimeDilationAmount = HazeWorldSettings.GetEffectiveTimeDilation();				
				
				if(TimeDilationAmount != LastTimeDilationAmountRtpcValue)
				{
					UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_Globals_TimeDilation_Amount_Gameplay", TimeDilationAmount);
					LastTimeDilationAmountRtpcValue = TimeDilationAmount;
				}

				float SlowMoActiveValue = TimeDilationAmount >= 1 ? 0 : 1;				

				if(TimeDilationAmount <= 1 && SlowMoActiveValue != LastSlowMoActiveValue)
				{
					UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_Globals_TimeDilation_IsSlowmo_Gameplay", SlowMoActiveValue);
					LastSlowMoActiveValue = SlowMoActiveValue;

					if(!bHasEnteredSlowMo && TimeDilationAmount < 1 && !IsDebugActive())
					{
						AudioManager.BP_PlayEnterSlowMo();
						bHasEnteredSlowMo = true;
					}
				}			
				else if(TimeDilationAmount > 1 && LastSlowMoActiveValue == 1)
				{
					UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_Globals_TimeDilation_IsSlowmo_Gameplay", 0);
					LastSlowMoActiveValue = 0;
				}
				else if(TimeDilationAmount >= 1 && bHasEnteredSlowMo)
				{
					AudioManager.BP_PlayExitSlowMo();
					bHasEnteredSlowMo = false;
				}
			}
		}

		if(IsDebugActive() && bHasEnteredSlowMo)
		{
			AudioManager.BP_StopSlowMo();
			UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_Globals_TimeDilation_IsSlowmo_Gameplay", 0);			
			bHasEnteredSlowMo = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (LastSlowMoActiveValue != 0)
			UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_Globals_TimeDilation_IsSlowmo_Gameplay", 0);
		if (bHasEnteredSlowMo)
			AudioManager.BP_PlayExitSlowMo();

		bHasEnteredSlowMo = false;
		LastSlowMoActiveValue = 0;
	}
}