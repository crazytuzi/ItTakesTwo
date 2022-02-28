import Cake.LevelSpecific.PlayRoom.Circus.Cannon.CannonTargetOscillation;
class AClownBalloonActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Oscillation)
	USkeletalMeshComponent Skeletalmesh;

	UPROPERTY()
	bool bShouldRotate = false;

	UPROPERTY(DefaultComponent)
	UCannonTargetOscillation Oscillation;

	FVector GetPlayerMiddleLocation()
	{
		float PlayerDistance = Game::GetCody().ActorLocation.Distance(Game::GetMay().ActorLocation);

		if (PlayerDistance > 30000)
		{
			AHazePlayerCharacter Candidate;
			PlayerDistance = 999999999.f;

			for (auto Player : Game::GetPlayers())
			{
				if (Player.GetDistanceTo(this) < PlayerDistance)
				{
					Candidate = Player;
					PlayerDistance = Player.GetDistanceTo(this);
				}
				
			}
			FVector Pos = Candidate.ActorLocation;
			Pos.Z = Root.WorldLocation.Z;
			return Pos;
		}

		else
		{
			FVector MiddlePos;
			for (AHazePlayerCharacter Player : Game::GetPlayers())
			{
				MiddlePos += Player.ActorLocation;
			}

			MiddlePos *= 0.5f;
			MiddlePos.Z = Root.WorldLocation.Z;

			return MiddlePos;
		}
		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bShouldRotate)
		{
			FVector DirToMiddlePos = GetPlayerMiddleLocation() - Root.WorldLocation;
			FRotator LookRotation = FRotator::MakeFromX(DirToMiddlePos);
			
			FQuat Rotation = FQuat::Slerp(Skeletalmesh.WorldRotation.Quaternion(), LookRotation.Quaternion(), DeltaTime * 0.1f);

			Skeletalmesh.SetWorldRotation(Rotation);
		}
	}
}