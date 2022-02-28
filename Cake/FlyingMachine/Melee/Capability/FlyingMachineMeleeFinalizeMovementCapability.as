
import Cake.FlyingMachine.Melee.FlyingMachineMeleeComponent;
import Vino.Camera.Components.CameraUserComponent;


class UFlyingMachineMeleeFinalizeMovementCapability : UHazeMelee2DCapabilityBase
{
	default CapabilityTags.Add(n"FinalizeMelee");

	default TickGroup = ECapabilityTickGroups::AfterGamePlay;
	default TickGroupOrder = 200;

	default CapabilityDebugCategory = MeleeTags::Melee;

	UHazeCrumbComponent CrumbComponent;
	AHazeCharacter CharacterOwner;
	UCameraUserComponent Camera;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		CrumbComponent = UHazeCrumbComponent::Get(Owner);
		CharacterOwner = Cast<AHazeCharacter>(Owner);
		Camera = UCameraUserComponent::Get(Owner);
		MeleeComponent.EnableAttachment();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{	
		return EHazeNetworkActivation::ActivateLocal;	
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(const FCapabilityActivationParams& ActivationParams)
	{
		auto Player = Cast<AHazePlayerCharacter>(CharacterOwner);
		if(Player != nullptr)
			CrumbComponent.IncludeCustomParamsInActorReplication(FVector::ZeroVector, FRotator::ZeroRotator, this);		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{		
		auto Player = Cast<AHazePlayerCharacter>(CharacterOwner);
		if(Player != nullptr)
			CrumbComponent.RemoveCustomParamsFromActorReplication(this);			
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			MeleeComponent.LeaveMeleeCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized ReceivedParams;
			MeleeComponent.ConsumeMeleeCrumbTrail(DeltaTime, ReceivedParams);
		}

		FHazeMelee2DSpineData SplineData;
		MeleeComponent.GetSplineData(SplineData);
		CharacterOwner.ChangeActorWorldUp(SplineData.WorldUp);

		// This will break the camera
		// if(Camera != nullptr)
		// 	Camera.SnapCamera(-CharacterOwner.GetActorForwardVector());
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		FString Str = "";
		Str += "RelativeLocation: " + Owner.GetRootComponent().GetRelativeTransform().GetLocation();
		return Str;	
	}
}
