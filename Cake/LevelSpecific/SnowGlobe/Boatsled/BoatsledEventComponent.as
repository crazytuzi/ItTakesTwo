import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledJumpParams;

event void FOnBoatsledEvent();

event void FOnBoatsledStartLightMark(int Count);

event void FOnBoatsledInteractionStartedEvent();
event void FOnPlayerStoppedSleddingEvent(AHazePlayerCharacter PlayerCharacter);

event void FOnBoatsledPreJumpRubberBandEvent(float JumpDistanceAlongSpline);
event void FOnBoatsledStartingJumpEvent(FBoatsledJumpParams BoatsledJumpParams);
event void FOnBoatsledLandingEvent(FVector LandingVelocity);

event void FOnBoatsledApproachingTunnelEndEvent(FVector TunnelEndLocation);
event void FOnBoatsledFallingThroughChimneyEvent(UHazeSplineComponent SplineComponent, UHazeSplineComponent SplineTrackAfterFallthrough);
event void FOnBoatsledWhaleRampUpEvent();

event void FOnBoatsledBoostEvent();

event void FOnBoatsledCompletedEvent(AHazePlayerCharacter PlayerCharacter);

class UBoatsledEventComponent : UActorComponent
{
	// START STUFF
	UPROPERTY()
	FOnBoatsledInteractionStartedEvent OnBoatsledInteractionStarted;

	UPROPERTY()
	FOnBoatsledInteractionStartedEvent OnBothPlayersWaitingForStart;

	UPROPERTY()
	FOnBoatsledStartLightMark OnStartLightMark;

	UPROPERTY()
	FOnBoatsledEvent OnGreenStartLight;


	// PUSH START STUFF
	UPROPERTY()
	FOnBoatsledEvent OnPlayerHoppingAboard;

	// RIDE END STUFF
	UPROPERTY()
	FOnPlayerStoppedSleddingEvent OnPlayerStoppedSledding;

	UPROPERTY()
	FOnBoatsledEvent OnBoatsledRideAlmostOver;

	UPROPERTY()
	FOnBoatsledCompletedEvent OnBoatsledCompleted;

	UPROPERTY()
	FOnBoatsledEvent OnBothPlayersStoppedSledding;


	// JUMP STUFF
	// Fired by BoatsledJumpSplineRegion when entering region
	UPROPERTY()
	FOnBoatsledPreJumpRubberBandEvent OnBoatsledPreJumpRubberBand;

	// Fired by BoatsledJumpSplineRegion when exiting region
	UPROPERTY()
	FOnBoatsledStartingJumpEvent OnBoatsledStartingJump;

	UPROPERTY()
	FOnBoatsledLandingEvent OnBoatsledLanding;


	// TRACK STUFF
	UPROPERTY()
	FOnBoatsledEvent OnBoatsledWhaleSleddingStarted;

	UPROPERTY()
	FOnBoatsledApproachingTunnelEndEvent OnBoatsledApproachingTunnelEnd;

	UPROPERTY()
	FOnBoatsledFallingThroughChimneyEvent OnBoatsledFallingThroughChimney;

	UPROPERTY()
	FOnBoatsledWhaleRampUpEvent OnBoatsledWhaleRampUp;


	// BOOST STUFF
	UPROPERTY()
	FOnBoatsledBoostEvent OnBoatsledBoost;
}