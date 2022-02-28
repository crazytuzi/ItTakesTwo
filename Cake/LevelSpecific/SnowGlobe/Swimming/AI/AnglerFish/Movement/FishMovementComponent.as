import Vino.Movement.Components.MovementComponent;
import Vino.AI.Components.GentlemanFightingComponent;

class UFishMovementComponent : UHazeMovementComponent
{
	FVector GetHidingPlayerAvoidanceDestination(const FVector& Dest, AHazePlayerCharacter Player)
	{
		if (Player == nullptr) 
			return Dest;

		UGentlemanFightingComponent GentlemanComp = UGentlemanFightingComponent::Get(Player);
		if (GentlemanComp == nullptr)
			return Dest;
		
		if (!GentlemanComp.HasTag(n"FishHiding"))
			return Dest;

		// Player in hiding, try to stay away
		FVector PlayerLoc = Player.ActorLocation;
		FVector PlayerLocProjectedOnLine;
		float Fraction;
		float MinDist = 8000.f;
		if (Math::ProjectPointOnLineSegment(Owner.ActorLocation, Dest, PlayerLoc, PlayerLocProjectedOnLine, Fraction) || (Owner.GetDistanceTo(Player) < MinDist))
		{
			// We're near or passing by player
			float PassageDistSqr = PlayerLocProjectedOnLine.DistSquared(PlayerLoc);
			if (PassageDistSqr < FMath::Square(MinDist))
			{
				FVector SafeLoc = PlayerLoc + (PlayerLocProjectedOnLine - PlayerLoc).GetSafeNormal() * MinDist;
				FVector AdjustedLoc = Owner.ActorLocation + (SafeLoc - Owner.ActorLocation).GetSafeNormal() * (Dest - Owner.ActorLocation).Size();
				return AdjustedLoc;
			}
		} 
		return Dest;
	}
}