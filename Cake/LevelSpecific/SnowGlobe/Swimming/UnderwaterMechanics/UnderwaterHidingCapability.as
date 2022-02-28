import Cake.LevelSpecific.SnowGlobe.Swimming.UnderwaterMechanics.UnderwaterHidingComponent;

class UUnderwaterHidingCapability : UHazeCapability
{
	AHazePlayerCharacter Player;
	UUnderwaterHidingComponent HidingComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		HidingComp = UUnderwaterHidingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (HidingComp.AvailableHidingPlaces.Num() <= 0)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (HidingComp.AvailableHidingPlaces.Num() <= 0)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HidingComp.ActiveHidingPlace != nullptr)
		{
			float Distance = (Player.GetActorLocation() - HidingComp.ActiveHidingPlace.Spline.FindLocationClosestToWorldLocation(Player.GetActorLocation(), ESplineCoordinateSpace::World)).Size();
	
			if (Distance > HidingComp.ActiveHidingPlace.Radius + 100.f)
			{
				HidingComp.ActiveHidingPlace = nullptr;
				HidingComp.LastHidingPlace = nullptr;
				HidingComp.bIsHiding = false;
			}
		}
		else
		{
			HidingComp.ActiveHidingPlace = GetClosestHidingPlace(Player.GetActorLocation());
		}
	}

	AFishHidingPlaceSpline GetClosestHidingPlace(FVector Location)
	{
		AFishHidingPlaceSpline ClosestHidingPlace = nullptr;
		float ClosestDistance = BIG_NUMBER;

		for (auto HidingPlace : HidingComp.AvailableHidingPlaces)
		{
			float Distance = (Location - HidingPlace.Spline.FindLocationClosestToWorldLocation(Location, ESplineCoordinateSpace::World)).Size();

			if (Distance < HidingPlace.Radius)
			{
				if (Distance < ClosestDistance)
				{
					ClosestDistance = Distance;
					ClosestHidingPlace = HidingPlace;
				}
			}			
		}

		return ClosestHidingPlace;
	}

}