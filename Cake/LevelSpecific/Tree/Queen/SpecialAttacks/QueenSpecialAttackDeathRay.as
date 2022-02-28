import Cake.LevelSpecific.Tree.Queen.SpecialAttacks.QueenSpecialAttackComponent;
import Cake.LevelSpecific.Tree.Queen.QueenFacingComponent;
import Cake.LevelSpecific.Tree.Queen.DeathRay.QueenDeathRayDamageDecalActor;

UCLASS(Abstract)
class UQueenSpecialAttackDeathRay : UQueenSpecialAttackComponent
{
	UPROPERTY()
	TArray<AHazePlayerCharacter> PlayersDoneRoundTrip;

	UPROPERTY()
	FName BoneName;

	UPROPERTY()
	bool bDeathRayIsActive = false;


	UPROPERTY()
	UQueenFacingComponent FacingComponent;

	UPROPERTY()
	AQueenDeathrayDamageDecalActor DamageDecal;

	TArray<AQueenDeathrayDamageDecalActor> DecalActors;

	const float SocketDistances = 150;
	const bool bDebug = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<AActor> Actors;
		
		Gameplay::GetAllActorsOfClass(AQueenDeathrayDamageDecalActor::StaticClass(), Actors);

		for (AActor Actor : Actors)
		{
			DecalActors.Add(Cast<AQueenDeathrayDamageDecalActor>(Actor));
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float Deltatime)
	{
		if (bDeathRayIsActive)
		{
			FVector Direction =  Queen.Mesh.GetSocketQuaternion(BoneName).ForwardVector;


			for (auto Player : Game::GetPlayers())
			{

				FVector LeftStart = Queen.Mesh.GetSocketLocation(BoneName) + Queen.Mesh.GetSocketQuaternion(BoneName).RightVector * SocketDistances;
				LeftStart.Z = -476;
				FVector LeftStartLeftDir = Queen.Mesh.GetSocketQuaternion(BoneName).RightVector;
				
				LeftStartLeftDir.Z = 0;
				LeftStartLeftDir = LeftStartLeftDir.GetSafeNormal();
				LeftStartLeftDir *= -1;

				FVector RightStart = Queen.Mesh.GetSocketLocation(BoneName) + Queen.Mesh.GetSocketQuaternion(BoneName).RightVector * -SocketDistances;
				RightStart.Z = -476;
				FVector RightStartRightDir = Queen.Mesh.GetSocketQuaternion(BoneName).RightVector * -1;
				RightStartRightDir.Z = 0;
				RightStartRightDir = RightStartRightDir.GetSafeNormal();
				RightStartRightDir *= -1;

				FVector DirectionToPlayerRightStart = Player.ActorLocation - RightStart;
				FVector DirectionToPlayerLeftStart = Player.ActorLocation - LeftStart;

				DirectionToPlayerRightStart.Z = 0;
				DirectionToPlayerLeftStart.Z = 0;

				DirectionToPlayerRightStart = DirectionToPlayerRightStart.GetSafeNormal();
				DirectionToPlayerLeftStart = DirectionToPlayerLeftStart.GetSafeNormal();

				float DotToLeftStart = DirectionToPlayerLeftStart.DotProduct(LeftStartLeftDir);
				float DotToRightStart = DirectionToPlayerRightStart.DotProduct(RightStartRightDir);

				FLinearColor LeftSphereColor = FLinearColor::Red;
				FLinearColor RightSphereColor = FLinearColor::Red;

				FVector DirToQueen = Player.ActorLocation - Queen.ActorLocation;
				DirToQueen = DirToQueen.GetSafeNormal();
				float DotToForward = DirToQueen.DotProduct(Queen.ActorForwardVector);

				if (DotToForward < 0.3f)
				{
					continue;
				}

				if (DotToLeftStart > 0)
				{
					LeftSphereColor = FLinearColor::Green;
				}

				if (DotToRightStart > 0)
				{
					RightSphereColor = FLinearColor::Green;
				}

				if (DotToRightStart > 0 && DotToLeftStart > 0)
				{
					Player.DamagePlayerHealth(1);
				}

				for(AQueenDeathrayDamageDecalActor Decal : DecalActors)
				{
					if (!Decal.IsActorDisabled())
						continue;

					FVector FlatDirection = Direction;
					FlatDirection.Z = 0;
					FlatDirection = FlatDirection.GetSafeNormal();

					FVector DirToDecal = Decal.ActorLocation - Queen.Mesh.GetSocketLocation(BoneName);
					DirToDecal.Z = 0;
					DirToDecal = DirToDecal.GetSafeNormal();

					float Dot = DirToDecal.DotProduct(FlatDirection);

					if (Dot > 0.98f && Decal.IsActorDisabled(nullptr))
					{
						Decal.EnableActor(nullptr);
					}
				}

				if (bDebug)
				{
					System::DrawDebugSphere(RightStart, 100, 12, RightSphereColor);
					System::DrawDebugSphere(LeftStart, 100, 12, LeftSphereColor);

					System::DrawDebugArrow(Game::GetMay().ActorLocation, Game::GetMay().ActorLocation + Direction * SocketDistances, 5);
					System::DrawDebugArrow(LeftStart, LeftStart + LeftStartLeftDir * SocketDistances, 5);
					System::DrawDebugArrow(RightStart, RightStart + RightStartRightDir * SocketDistances, 5);
				}
			}

			FacingComponent.UpdateRotation(Queen.Mesh.GetSocketQuaternion(BoneName).ForwardVector, Queen.Mesh.GetSocketLocation(BoneName));
		}
	}
}