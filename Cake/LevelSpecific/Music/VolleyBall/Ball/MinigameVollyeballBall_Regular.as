import Cake.LevelSpecific.Music.VolleyBall.Ball.MinigameVollyeballBall;

UCLASS(Abstract)
class AMinigameVolleyballBall_Regular : AMinigameVolleyballBall
{
	int TouchesLeftToFail = 0;
	FVector ForwardRotationDir;
	float MovementSize = 0;
		
	protected void Crumb_AddSpawnForce(const FHazeDelegateCrumbData& CrumbData) override
	{
		Super::Crumb_AddSpawnForce(CrumbData);
		ForwardRotationDir = CrumbData.GetVector(n"InitialVelocity");
		MovementSize = 1.f;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime) override
	{
		Super::Tick(DeltaTime);
		FRotator DeltaRot = Math::MakeRotFromZ(ForwardRotationDir);
		DeltaRot *= DeltaTime * MovementSize;
		Mesh.AddRelativeRotation(DeltaRot);
	}

	bool IsValidUpdate(AHazePlayerCharacter Player, FVolleyballHitBallData Data, FVolleyballReplicatedEOLData& OutUpdateData) const override
	{
		if(!Data.bHasTouchedBall && Movement.IsGrounded())
		{
			OutUpdateData.ScoringPlayer = Player.GetOtherPlayer().Player;
			OutUpdateData.EffectToSpawn = GroundImpactEffectType;
			return false;
		}

		return true;
	}

	FVolleyballHitBallData HitByPlayer(AHazePlayerCharacter Player, bool bPlayerIsGrounded, bool bPlayerIsDashing) override
	{
		FVector ClosestPoint;
		_Net.GetClosestPointOnCollision(GetActorLocation(), ClosestPoint);
		ForwardRotationDir = (ClosestPoint - GetActorLocation());
		ForwardRotationDir += Movement.GetVelocity();
		ForwardRotationDir.GetSafeNormal();
		MovementSize = FMath::Min(Movement.GetVelocity().Size() / 1000.f, 10.f);

		FVolleyballHitBallData OutStatus;
		if(_MovingType == EMinigameVolleyballMoveType::DecendingToFail)
		{
			OutStatus.bIsBadTouch = true;
			return OutStatus;
		}
		
		const EHazePlayer CurrentControllingPlayer = ControllingPlayer;
		if(!bPlayerIsGrounded)
		{
			if(bPlayerIsDashing)
				AddSmashForce(Player);
			else
				AddUpAndOverForce(Player, FMath::RandRange(100.f, 300.f));	
		}
		else
		{
			if(bPlayerIsDashing)
				AddSmashForce(Player);
			else
				AddUpAndOverForce(Player);
			// if(bPlayerIsDashing)
			// 	AddUpAndOverForce(Player);
			// else
			// 	AddServeForce(Player);	
		}

		OutStatus.bSwappedPlayer = ControllingPlayer != CurrentControllingPlayer;

		if(_MovingType == EMinigameVolleyballMoveType::DecendingToFail)
		{
			OutStatus.bHasTouchedBall = false;
			OutStatus.bIsBadTouch = true;
		}
	
		return OutStatus;
	}

	bool OnServeForceAdded() override
	{ 
		if(TouchesLeftToFail == 0)
			SetBounceLeftToFail(3);
		else
			SetBounceLeftToFail(TouchesLeftToFail - 1);
		
		// No more bounce
		if(TouchesLeftToFail == 0)
		{
			_MovingType = EMinigameVolleyballMoveType::DecendingToFail;
			return false;
		}

		return true;
	}

	bool OnUpAndOverForceAdded() override
	{
		SetBounceLeftToFail(0);
		return true; 
	}

	bool OnSmashForceAdded() override
	{
		SetBounceLeftToFail(0);
		return true; 
	}

	void SetBounceLeftToFail(int NewIndex)
	{
		TouchesLeftToFail = NewIndex;
		if(TouchesLeftToFail == 0)
		{
			CodyText.SetText(FText());
			MayText.SetText(FText());
		}
		else
		{
			CodyText.SetText(FText::FromString("" + TouchesLeftToFail));
			MayText.SetText(FText::FromString("" + TouchesLeftToFail));
		}
	}
}