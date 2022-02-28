
import Peanuts.Aiming.AutoAimStatics;
import Vino.Camera.Components.CameraUserComponent;
import Vino.Camera.Capabilities.CameraControlCapability;
import Cake.LevelSpecific.Garden.Vine.VineComponent;

class UVineCameraCapability : UCameraControlCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroupOrder = TickGroupOrder - 1;
	default CapabilityDebugCategory = n"LevelSpecific";

	AHazePlayerCharacter Player;
	UVineComponent VineComp;
	
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		Player = Cast<AHazePlayerCharacter>(Owner);
		VineComp = UVineComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!VineComp.bAiming)
			return EHazeNetworkActivation::DontActivate;

		return Super::ShouldActivate();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!VineComp.bAiming)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return Super::ShouldDeactivate();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);

		SetMutuallyExclusive(CameraTags::Control, true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Super::OnDeactivated(DeactivationParams);

		SetMutuallyExclusive(CameraTags::Control, false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		// const FAutoAimLine AutoAimData = GetAutoAimForTargetLine(Player, Player.ViewLocation, Player.ViewRotation.Vector(), 0.f, 8000.f, true);
		// UAutoAimTargetComponent AutoAimComp = AutoAimData.AutoAimedAtComponent;

		// if(AutoAimComp != nullptr)
		// {
		// 	FVector2D ScreenPos;
		// 	SceneView::ProjectWorldToViewpointRelativePosition(Player, AutoAimComp.GetWorldLocation(), ScreenPos);
		// 	VineComp.SetWidgetScreenSpace(ScreenPos);
		// }
		// else
		// {
		// 	//VineComp.SetWidgetScreenSpace(FVector2D(0.5f, 0.5f));
		// }
	}

	FRotator GetFinalizedDeltaRotation(FRotator InRotation)
	{
		return InRotation;
	}

}
