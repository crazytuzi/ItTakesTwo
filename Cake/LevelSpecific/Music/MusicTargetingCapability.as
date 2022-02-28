import Cake.LevelSpecific.Music.MusicTargetingComponent;
import Cake.LevelSpecific.Music.MusicImpactComponent;

UCLASS(Abstract)
class UMusicTargetingCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 60;

	TArray<AActor> IgnoreActors;

	AHazePlayerCharacter Player;
	UMusicTargetingComponent TargetingComp;
	TSubclassOf<UHazeActivationPoint> ActivationPointClass;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		TargetingComp = UMusicTargetingComponent::Get(Owner);
	}

	float GetTargetingMaxTrace() const
	{
		devEnsure(false, "No implementation of GetMaxTrace()!");
		return 1.0f;
	}

	FVector GetTraceStartPoint() const
	{
		devEnsure(false, "No implementation of GetTraceStartPoint()!");
		return Owner.ActorCenterLocation;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!TargetingComp.bIsTargeting)
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TargetingComp.StartTargeting();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const FVector TraceFrom = TargetingComp.GetTraceStartPoint();
		bool bClearImpact = true;
		
		// Read the last point so we try to trace as short as possible
		float MaxTrace = GetTargetingMaxTrace();
		UHazeActivationPoint LastPoint = Player.GetTargetPoint(ActivationPointClass);
		if(LastPoint != nullptr)
			MaxTrace = FMath::Min(LastPoint.GetTransformFor(Player).Location.Distance(TraceFrom) + 1000.f, MaxTrace);

		if(IsDebugActive())
			PrintToScreen("TraceDistance = " + MaxTrace);
		
		// This will update the traces before we go into the querry
		const FVector TraceTo = TraceFrom + (Player.ViewRotation.Vector() * MaxTrace);
		TargetingComp.AutoAimTrace = GetAutoAimForTargetLine(Player, Player.ViewLocation, (TraceTo - TraceFrom).GetSafeNormal(),  0.f, MaxTrace, false);
		TargetingComp.GetImpactTrace(TraceFrom, TraceTo, TargetingComp.ImpactTrace, IsDebugActive());
				
		// We query using the new traces
		Player.UpdateActivationPointAndWidgets(ActivationPointClass);

		// This is the new best query
		FHazeQueriedActivationPoint CurrentTargetQuerry;
		if(Player.GetTargetPoint(ActivationPointClass, CurrentTargetQuerry))
		{
			UMusicImpactComponent MusicImpact = Cast<UMusicImpactComponent>(CurrentTargetQuerry.Point);
			if(MusicImpact != nullptr)
			{
				FHazeHitResult Hit;
				CurrentTargetQuerry.GetStoredTraceResult(Hit);
				TargetingComp.UpdateImpactHitResult(Player, MusicImpact, Hit);
				bClearImpact = false;
			}	
		}

		if(bClearImpact)
		{
			TargetingComp.UpdateImpactHitResult(Player, nullptr, TargetingComp.ImpactTrace);
		}
	}

	// Override and do stuff
	void OnTargetFound(UMusicImpactComponent MusicImpact) {}
	void OnTargetLost() {}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!TargetingComp.bIsTargeting)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		TargetingComp.StopTargeting();
	}
}
