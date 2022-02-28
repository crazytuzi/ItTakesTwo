enum EGrindAttachReason
{
	Proximity,
	Grapple,
	Transfer,
	Connection,
}

enum EGrindTargetReason
{
	Grapple,
	Transfer
}

enum EGrindDetachReason
{
	EndOfSpline,
	Connection,
	Jump,
	Transfer,
	Obstructed,
	CapabilityBlocked,
	Cancel,
}

enum EGrindSplineTravelDirection
{
	Bidirectional,
	Forwards,
	Backwards
}

enum EGrindSplineTransferDirection
{
	TransferBidirectional,
	TransferFrom,
	TransferTo
}
