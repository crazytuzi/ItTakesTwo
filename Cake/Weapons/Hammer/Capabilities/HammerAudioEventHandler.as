import Cake.Weapons.Hammer.Capabilities.HammerEventHandler;
import Peanuts.Audio.AudioStatics;
import Vino.Audio.PhysMaterials.PhysicalMaterialAudio;

UCLASS()
class UHammerAudioEventHandler : UHammerEventHandler 
{
	UHazeAkComponent HazeAkComp;

	FString LastImpactSwitch = "";

	default CapabilityTags.Add(n"HammerAudio");

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		// Call parent function first
		Super::Setup(SetupParams);
		HazeAkComp = Hammer.HazeAkComp;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// Call parent function first
		Super::OnActivated(ActivationParams);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// Call parent function first
		Super::OnDeactivated(DeactivationParams);
	}

	UFUNCTION(BlueprintOverride)
	void HandleHammerHit(FHitResult HammerNoseHitData) 
	{
		// const float DebugTime = 4.f;
		// FLinearColor DebugColor = HammerNoseHitData.bBlockingHit ? FLinearColor::Yellow : FLinearColor::Red;
		// PrintToScreen("Hammer cone attack started", DebugTime, DebugColor);
		// System::DrawDebugSphere( HammerNoseHitData.TraceStart, 20.f);

		TArray<FString> SwitchData;
		UPhysicalMaterialAudio AudioMaterial = PhysicalMaterialAudio::GetPhysicalMaterialAudioAsset(HammerNoseHitData.Component);

		if(AudioMaterial != nullptr)
		{
			AudioMaterial.GetMaterialSwitch(SwitchData);

			if(SwitchData.Num() == 2 && SwitchData[1] != LastImpactSwitch)
			{
				HazeAkComp.SetSwitch(SwitchData[0], SwitchData[1]);
				LastImpactSwitch = SwitchData[1];
			}
		}
		
		HazeAkComp.HazePostEvent(Hammer.HitImpactEvent);

		//Print("HammerHitMaterial"+ AudioMaterial, 3.f);
	}

	UFUNCTION(BlueprintOverride)
	void HandleHammerSwingSwitchedDirection() 
	{
		 //PrintToScreen("Swing Switched Drection", 0.25f, FLinearColor::White);

		 HazeAkComp.HazePostEvent(Hammer.SwingDirectionChangeEvent);
	}

	UFUNCTION(BlueprintOverride)
	void HandleHammerSwingStarted() 
	{
		// PrintToScreen("Swing Started", 3.f, FLinearColor::Yellow);

		HazeAkComp.HazePostEvent(Hammer.SwingStartEvent);
	}

	UFUNCTION(BlueprintOverride)
	void HandleHammerSwingEnded() 
	{
		// PrintToScreen("Swing Ended", 3.f, FLinearColor::Red);

		 HazeAkComp.HazePostEvent(Hammer.SwingStopEvent);
	}

}