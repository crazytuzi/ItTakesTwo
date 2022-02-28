import Vino.Movement.Swinging.SwingComponent;
import Vino.ActivationPoint.ActivationPointStatics;
import Vino.Movement.MovementSystemTags;


class USwingSeekNearbyCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::Swinging);
	default CapabilityTags.Add(n"SwingingSeek");

	default CapabilityDebugCategory = n"Movement Swinging";

	default TickGroup = ECapabilityTickGroups::Input;
	default TickGroupOrder = 50;

	AHazePlayerCharacter OwningPlayer;
	USwingingComponent SwingingComponent;	

	TArray<FHazeQueriedActivationPoint> FoundPoints;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		OwningPlayer = Cast<AHazePlayerCharacter>(Owner);
		SwingingComponent = USwingingComponent::GetOrCreate(Owner);
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
	void TickActive(float DeltaTime)
	{	
#if TEST
		if (IsDebugActive())
		{
			TArray<FHazeQueriedActivationPoint> Queries;
			OwningPlayer.QueryActivationPoints(USwingPointComponent::StaticClass(), Queries);

			for(FHazeQueriedActivationPoint& SwingPointQuery : Queries)
			{
				FLinearColor SwingPointLineColor;
				if (SwingPointQuery.CanBeSelected())
					SwingPointLineColor = FLinearColor::Green;
				else if (SwingPointQuery.DistanceType == EHazeActivationPointDistanceType::Selectable)
					SwingPointLineColor = FLinearColor::Yellow;
				else if  (SwingPointQuery.DistanceType == EHazeActivationPointDistanceType::Targetable)
					SwingPointLineColor = FLinearColor(1.f, 0.25f, 0.f);
				else
					SwingPointLineColor = FLinearColor::Red;
				
				System::DrawDebugLine(OwningPlayer.CapsuleComponent.WorldLocation, SwingPointQuery.Point.WorldLocation, SwingPointLineColor, Thickness = 2.f);
			}
		}
#endif

		OwningPlayer.UpdateActivationPointAndWidgets(USwingPointComponent::StaticClass());
	}	
}
