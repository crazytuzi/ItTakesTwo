import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;

UCLASS(HideCategories = "Activation Cooking Tags AssetUserData Collision")
class UMagnetSnowCanonComponent : UMagneticComponent
{
	bool IsMagneticPathBlocked(AHazePlayerCharacter Player, UMagneticComponent MagneticComponent) const
	{
		FVector MagnetToPlayer = (Player.ActorLocation - WorldLocation).GetSafeNormal();
		if (MagnetToPlayer.DotProduct(ForwardVector) > 0.3f)
			return true;

		FHitResult Hit;
		TArray<AActor> ActorsToIgnore;
		ActorsToIgnore.Add(Game::GetCody());
		ActorsToIgnore.Add(Game::GetMay());
		ActorsToIgnore.Add(Owner);

		System::LineTraceSingle(WorldLocation, MagneticComponent.WorldLocation, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, false, FLinearColor::Green);

		return Hit.bBlockingHit;
	}

	UFUNCTION(BlueprintOverride)
    EHazeActivationPointStatusType SetupActivationStatus(AHazePlayerCharacter Player, FHazeQueriedActivationPoint& Query)const override
    {
		if(bIsDisabled)
		{
			return EHazeActivationPointStatusType::InvalidAndHidden;
		}
		else if(DisabledForObjects.Contains(Player))
		{
			return EHazeActivationPointStatusType::InvalidAndHidden;	
		}

        UMagneticComponent PlayerMagComponent = UMagneticComponent::Get(Player);
		if (IsMagneticPathBlocked(Player, PlayerMagComponent))
			return EHazeActivationPointStatusType::Invalid;

        return Super::SetupActivationStatus(Player, Query);
    }
}