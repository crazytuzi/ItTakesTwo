import Cake.LevelSpecific.Music.VolleyBall.Ball.MinigameVollyeballBall;

UCLASS(Abstract)
class AMinigameVollyeballBall_Spike : AMinigameVolleyballBall
{
	protected void Crumb_AddSpawnForce(const FHazeDelegateCrumbData& CrumbData) override
	{
		_MovingType = EMinigameVolleyballMoveType::Serve;
		SmashTrail.Deactivate();
		RemoveCustomGravity();
			
		if(!HasControl())
			return;

		auto MovementSettings = UMovementSettings::GetSettings(this);
		UMovementSettings::SetGravityMultiplier(this, MovementSettings.GravityMultiplier * 6, Instigator = this);
		FVector From = GetActorLocation();
		FVector To = _TargetLocations[int(_ControllingPlayer)].GetWorldLocation();
		
		FVector OffsetDir = FRotator(0.f, FMath::RandRange(-180, 180), 0.f).Vector();
		OffsetDir *= FMath::RandRange(0, 50);
		To += OffsetDir;

		float Gravity = Movement.GetGravityMagnitude();
		float Height = 500.f;
		FOutCalculateVelocity TrajectoryData = CalculateParamsForPathWithHeight(From, To, Gravity, Height);
		FVector WantedImpulse = TrajectoryData.Velocity;

		PendingControlSideImpulses.Add(WantedImpulse);
	}

	bool IsValidUpdate(AHazePlayerCharacter Player, FVolleyballHitBallData Data, FVolleyballReplicatedEOLData& OutUpdateData) const override
	{
		if(Data.bHasTouchedBall)
		{
			OutUpdateData.ScoringPlayer = Player.GetOtherPlayer().Player;
			OutUpdateData.EffectToSpawn = PlayerImpactEffectType;
			return false;
		}

		if(Movement.IsGrounded())
		{
			OutUpdateData.EffectToSpawn = GroundImpactEffectType;
			return false;
		}

		return true;
	}

	FVolleyballHitBallData HitByPlayer(AHazePlayerCharacter Player, bool bPlayerIsGrounded, bool bPlayerIsDashing) override
	{
		FVolleyballHitBallData OutStatus;
		OutStatus.bHasTouchedBall = true;
		OutStatus.bIsBadTouch = true;
		return OutStatus;
	}
}