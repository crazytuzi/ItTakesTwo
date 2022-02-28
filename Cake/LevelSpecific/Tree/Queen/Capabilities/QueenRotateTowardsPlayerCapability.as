
import Cake.LevelSpecific.Tree.Queen.Capabilities.QueenBaseCapability;
import Rice.Positions.GetClosestPlayer;

UCLASS()
class UQueenRotateTowardsPlayerCapability : UQueenBaseCapability 
{
	FVector StartForwardDirection;

	FVector GetLookatPosition() property
	{
		FVector LookatLocation;

		if (Queen.QueenPhase == EQueenPhaseEnum::Phase3)
		{
			return Queen.ActorLocation + FVector::ForwardVector * - 1000;
		}

		if (IsActioning(n"SpecialAttack"))
		{
			return Queen.ActorLocation + FVector::ForwardVector * - 1000;
		}

		else if (Queen.OverrideLookatPosition != nullptr)
		{
			return Queen.OverrideLookatPosition.ActorLocation;
		}

		else if(IsBothPlayerInFrontOfQueen)
		{
			FVector MiddlePosition = Game::GetCody().ActorLocation + Game::GetMay().ActorLocation;
			MiddlePosition *= 0.5f;

			return MiddlePosition;
		}

		else if (Queen.InFrontOfQueenArea.IsOverlappingActor(Game::GetCody()))
		{
			return Game::GetCody().ActorLocation;
		}

		else if (Queen.InFrontOfQueenArea.IsOverlappingActor(Game::GetMay()))
		{
			return Game::GetMay().ActorLocation;
		}

		else
		{
			return GetClosestPlayer(Queen.ActorLocation).ActorLocation;
		}
	}

	bool GetIsBothPlayersBehindQueen() property
	{
		if (Queen.BehindQueenArea.IsOverlappingActor(Game::GetCody()) &&
			Queen.BehindQueenArea.IsOverlappingActor(Game::GetMay()))
		{
			return true;
		}
		
		else
		{
			return false;
		}
	}

	bool GetIsBothPlayerInFrontOfQueen() property
	{
		if (Queen.InFrontOfQueenArea.IsOverlappingActor(Game::GetCody()) &&
			Queen.InFrontOfQueenArea.IsOverlappingActor(Game::GetMay()))
		{
			return true;
		}
		
		else
		{
			return false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams) override
	{
		Super::Setup(SetupParams);
		StartForwardDirection = Queen.GetActorForwardVector();
	}

 	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		UpdateRotation(DeltaSeconds);
	}

	void UpdateRotation(float DeltaTime)
	{
		if (Queen.HasControl())
		{
			FVector LookatVec = LookatPosition - Queen.GetActorLocation();
			LookatVec.Z = 0;
			FRotator LOL = FRotator::MakeFromX(LookatVec);

			FQuat EndRotation = LOL.Quaternion();

			Queen.SyncQueenRotation.Value = EndRotation.Rotator();
		}
		
		Queen.SetActorRotation(FQuat::Slerp(Queen.ActorQuat, Queen.SyncQueenRotation.Value.Quaternion(), DeltaTime));
	}
}