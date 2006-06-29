/******************************************************************************
*******************************************************************************
**
**  Copyright (C) Sistina Software, Inc.  1997-2003  All rights reserved.
**  Copyright (C) 2004 Red Hat, Inc.  All rights reserved.
**
**  This copyrighted material is made available to anyone wishing to use,
**  modify, copy, or redistribute it subject to the terms and conditions
**  of the GNU General Public License v.2.
**
*******************************************************************************
******************************************************************************/

#ifndef __EAOPS_DOT_H__
#define __EAOPS_DOT_H__

struct gfs_ea_request;

struct gfs_eattr_operations {
	int (*eo_get) (struct gfs_inode *ip, struct gfs_ea_request *er);
	int (*eo_set) (struct gfs_inode *ip, struct gfs_ea_request *er);
	int (*eo_remove) (struct gfs_inode *ip, struct gfs_ea_request *er);
	char *eo_name;
};

unsigned int gfs_ea_name2type(const char *name, char **truncated_name);

extern struct gfs_eattr_operations gfs_user_eaops;
extern struct gfs_eattr_operations gfs_system_eaops;

extern struct gfs_eattr_operations *gfs_ea_ops[];

#endif /* __EAOPS_DOT_H__ */
