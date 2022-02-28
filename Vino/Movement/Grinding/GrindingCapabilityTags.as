namespace GrindingCapabilityTags
{   
	const FName Evaluate = n"GrindingEvaluate";

	/* Enter Tags */
	const FName Enter = n"GrindingEnter";
	const FName Transfer = n"GrindingEnterTransfer";
	const FName Grapple = n"GrindingEnterGrapple";
	const FName GrappleEvaluate = n"GrindingEnterGrappleEvaluate";
	const FName Proximity = n"GrindingEnterProximity";

	/* Grinding Tags */
	const FName Movement = n"GrindingMovement";
	const FName Dash = n"GrindingDash";	
	const FName Jump = n"GrindingJump";
	const FName TurnAround = n"GrindingTurnAround";
	const FName Camera = n"GrindingCamera";
	const FName Obsctruction = n"CharacterHitObstruction";
	const FName Speed = n"GrindingSpeed";
	const FName Cancel = n"GrindingCancel";
	const FName GrindMoveAction = n"GrindingMoveAction";

	const FName BlockedWhileGrinding = n"BlockedWhileGrinding";
}

namespace GrindingActivationEvents
{
	const FName TargetGrind = n"HasActiveTargetGrind";
	const FName Grinding = n"GrindingIsCurrentlyActive";
	const FName PotentialGrinds = n"GrindingHasPotentialGrinds";
	const FName GrappledForced = n"GrindingGrappleForced";
	const FName GrindJumping = n"GrindJumpCurrentlyActive";
	const FName Grappling = n"GrindGrapplingCurrentlyActive";
}
