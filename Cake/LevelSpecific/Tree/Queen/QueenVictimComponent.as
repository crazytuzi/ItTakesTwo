import Vino.PlayerHealth.PlayerHealthComponent;

UCLASS(HideCategories = "Cooking ComponentReplication Tags Sockets Clothing ClothingSimulation AssetUserData Mobile MeshOffset Collision Activation")
class UQueenVictimComponent : UActorComponent
{
	UPROPERTY(NotEditable)
	AHazePlayerCharacter PrimaryVictim = nullptr;

	UPROPERTY(NotEditable)
	AHazePlayerCharacter SecondaryVictim = nullptr;

	// whether the players are together or not. 
	bool bSeparated = false;

	void SwitchVictim()
	{
		if (PrimaryVictim == nullptr)
			PrimaryVictim = Game::GetMay();
		else
			PrimaryVictim = PrimaryVictim.GetOtherPlayer();

		SecondaryVictim = PrimaryVictim.GetOtherPlayer();
	}

	bool IsPlayerAliveAndGrounded(AHazePlayerCharacter InPlayer) const 
	{
		if(InPlayer == nullptr)
			return false;

		auto HealthComp = UPlayerHealthComponent::Get(InPlayer); 
		if(HealthComp.bIsDead)
			return false;

		return IsPlayerGrounded(InPlayer, 1000.f);
	}

	bool IsPlayerGrounded(AHazePlayerCharacter InPlayer, const float InTraceDistance = -1.f) const
	{
		auto PlayerMoveComp = UHazeBaseMovementComponent::Get(InPlayer);
		if(PlayerMoveComp.IsGrounded())
			return true;
		
		if(InTraceDistance > 0.f)
		{
			FHitResult HitData;

			TArray<AActor> IgnoreActors; 
			IgnoreActors.Add(Game::GetMay());
			IgnoreActors.Add(Game::GetCody());

			const FVector PlayerCenter = InPlayer.GetActorCenterLocation();

			const bool bHit = System::LineTraceSingle(
				PlayerCenter,
				PlayerCenter - FVector::UpVector * InTraceDistance,
				ETraceTypeQuery::Visibility,
				false,
				IgnoreActors,
				EDrawDebugTrace::None,
				HitData,
				true
			);

			return bHit;
		}

		return false;
	}

}