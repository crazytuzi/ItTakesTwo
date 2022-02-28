import Cake.LevelSpecific.Music.Cymbal.CymbalSettings;
import Cake.LevelSpecific.Music.Cymbal.CymbalComponent;
import Cake.LevelSpecific.Music.MusicTargetingCapability;

class UCymbalPlayerTargetingCapability : UMusicTargetingCapability
{
	default CapabilityTags.Add(n"Cymbal");

	UCymbalComponent CymbalComp;
	UCymbalSettings CymbalSettings;

	default ActivationPointClass = UCymbalImpactComponent::StaticClass();

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		CymbalComp = UCymbalComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(CymbalComp.bThrowWithoutAim)
			return EHazeNetworkActivation::ActivateLocal;
		
		return Super::ShouldActivate();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(CymbalComp.bThrowWithoutAim)
			return EHazeNetworkDeactivation::DontDeactivate;

		return Super::ShouldDeactivate();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		//if(!CymbalComp.bThrowWithoutAim)
			Super::OnActivated(ActivationParams);
		
		CymbalSettings = UCymbalSettings::GetSettings(CymbalComp.CymbalActor);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		//if(!CymbalComp.bThrowWithoutAim)
			Super::OnDeactivated(DeactivationParams);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(!CymbalComp.bTargeting)
			Player.UpdateActivationPointAndWidgets(UCymbalImpactComponent::StaticClass());
	}

	float GetTargetingMaxTrace() const
	{
		return CymbalSettings.MovementDistanceMaximum;
	}

	FVector GetTraceStartPoint() const
	{
		return CymbalComp.TraceStartPoint;
	}

	void OnTargetFound(UMusicImpactComponent MusicImpact)
	{
		UCymbalImpactComponent CymbalImpact = Cast<UCymbalImpactComponent>(MusicImpact);

		if(CymbalImpact != nullptr)
		{
			CymbalComp.CurrentTarget = CymbalImpact;
		}
	}

	void OnTargetLost() 
	{
		CymbalComp.CurrentTarget = nullptr;
	}
}
